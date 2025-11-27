local actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
-- local themes = require "telescope.themes"
local entry_display = require "telescope.pickers.entry_display"
local get_repos = require("projects.vfs").get_repos

local M = {}

local default_opts = {
  max_depth = 4,
  workspaces = {},
  recent_sign = "r",
  max_recent = 5,
}

local function project_finder(opts)
  local results = get_repos(opts.workspaces, opts.max_depth, opts.max_recent)
  local ws_name_len = 0
  for k, _ in pairs(opts.workspaces) do
    if ws_name_len < #k then
      ws_name_len = #k
    end
  end
  local proj_name_len = 0
  for _, v in ipairs(results) do
    if proj_name_len < #v.proj_rel_path then
      proj_name_len = #v.proj_rel_path
    end
  end

  local create_opts = {
    separator = " ",
    items = {
      { width = ws_name_len },
      { width = proj_name_len + 1 },
      { width = 2 },
      { remaining = true },
    },
  }

  local displayer = entry_display.create(create_opts)
  local make_display = function(entry)
    local project = entry.value
    local sign = project.tabnr or (project.recency and opts.recent_sign) or ""
    local display_opts = {
      { project.ws_name, "TelescopeResultsIdentifier" },
      { project.proj_rel_path },
      { sign, "TelescopeResultsNumber" },
      { project.proj_abs_path, "Comment" },
    }
    return displayer(display_opts)
  end

  return finders.new_table {
    results = results,
    entry_maker = function(project)
      return {
        value = project,
        ordinal = project.ws_name .. " " .. project.proj_rel_path,
        display = make_display,
      }
    end,
  }
end

local function cd_project(options, entry)
  local project = entry.value
  vim.notify("switched to project: " .. project.proj_abs_path)
  if project.tabnr then
    vim.fn.execute("tabn " .. project.tabnr, "silent")
  else
    vim.fn.execute("tabnew | tcd " .. project.proj_abs_path, "silent")
  end
  if options.on_tab_create then
    options.on_tab_create()
  end
end

local function projects_list(opts)
  local picker_opts = {}
  pickers
    .new(picker_opts, {
      prompt_title = "Select a project",
      results_title = "Projects",
      previewer = false,
      finder = project_finder(opts),
      sorter = conf.file_sorter(picker_opts),
      ---@diagnostic disable-next-line: unused-local
      attach_mappings = function(prompt_bufnr, map)
        local handler = function()
          local e = actions_state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          cd_project(opts, e)
        end
        actions.select_default:replace(handler)
        return true
      end,
    })
    :find()
end

M.setup = function(user_opts)
  local opts = vim.tbl_extend("force", default_opts, user_opts or {})
  vim.api.nvim_create_user_command("ProjectsList", function()
    projects_list(opts)
  end, {
    desc = "Show Project List",
  })
end

return M
