local actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
-- local themes = require "telescope.themes"
local entry_display = require "telescope.pickers.entry_display"

local M = {}

M.options = {
  maxdepth = 4,
  scm_dirs = { ".git" },
  workspaces = {},
  recent_sign = "r",
  recent_max = 5,
}

M.find_text = function(line, text, start, finish)
  line = line:sub(1, finish)
  local ranges = {}

  while true do
    local i, j = string.find(line, text, start, true)
    if not i then
      break
    end
    table.insert(ranges, { i - 1, j })
    start = j + 1
  end

  return ranges
end

M.project_finder = function(options)
  local results, max_wlen, max_plen = require("projects.vfs").find(options)
  local create_opts = {
    separator = " ",
    items = {
      { width = max_wlen },
      { width = max_plen + 1 },
      { width = 2 },
      { remaining = true },
    },
  }

  local displayer = entry_display.create(create_opts)
  local make_display = function(entry)
    local project = entry.value
    local full_path = project.ws_abspath .. "/" .. project.proj_relpath
    full_path = vim.fn.fnamemodify(full_path, ":~"):gsub("/+$", "")
    local sign = project.tabnr or (project.recent and options.recent_sign) or ""
    local display_opts = {
      { project.ws_name, "TelescopeResultsIdentifier" },
      { project.proj_relpath },
      { sign, "TelescopeResultsNumber" },
      { full_path, "Comment" },
    }
    local line, hls = displayer(display_opts)
    local sep_idx = M.find_text(line, "/", max_wlen + 1, max_wlen + max_plen + 2)
    if #sep_idx > 0 then
      for _, v in ipairs(sep_idx) do
        table.insert(hls, { v, "TelescopeResultsComment" })
      end
    end
    return line, hls
  end

  return finders.new_table {
    results = results,
    entry_maker = function(project)
      return {
        value = project,
        ordinal = project.ws_name .. " " .. project.proj_relpath,
        display = make_display,
      }
    end,
  }
end

M.cd_project = function(options, entry)
  local project = entry.value
  local path = project.ws_abspath .. "/" .. project.proj_relpath
  path = vim.fn.fnamemodify(path, ":p")
  path = path:gsub("/+$", "")
  vim.notify("switched to project: " .. path)
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local tabcwd = vim.fn.getcwd(-1, tabnr)
    if path == tabcwd then
      vim.fn.execute("tabn " .. tabnr, "silent")
      return
    end
  end

  require("projects.recent").update(path, options.recent_max)
  vim.fn.execute("tabnew | tcd " .. path, "silent")
  if options.on_tab_create then
    options.on_tab_create()
  end
end

M.projects_list = function(options)
  local opts = {}
  pickers
    .new(opts, {
      prompt_title = "Select a project",
      results_title = "Projects",
      previewer = false,
      finder = M.project_finder(options),
      sorter = conf.file_sorter(opts),
      ---@diagnostic disable-next-line: unused-local
      attach_mappings = function(prompt_bufnr, map)
        local handler = function()
          local e = actions_state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          M.cd_project(options, e)
        end
        actions.select_default:replace(handler)
        return true
      end,
    })
    :find()
end

M.setup = function(options)
  options = vim.tbl_deep_extend("force", M.options, options or {})
  vim.api.nvim_create_user_command("ProjectsList", function()
    M.projects_list(options)
  end, {
    desc = "Show Project List",
  })
end

return M
