local M = {}

M.is_project_dir = function(dir, options)
  for _, v in ipairs(options.scm_dirs) do
    local sdir = dir .. "/" .. v
    if vim.loop.fs_stat(sdir) then
      return true
    end
  end
end

M.is_venv_dir = function(dir)
  if vim.loop.fs_stat(dir .. "/" .. "pyvenv.cfg") then
    return true
  end
end

M.find_repos = function(ws_dir, options)
  ws_dir = vim.fn.expand(ws_dir)
  if M.is_project_dir(ws_dir, options) then
    return { "" }
  end
  local repos = {}

  local function scan_dir(dir, depth)
    if depth > options.maxdepth then
      return
    end

    local iterator = vim.loop.fs_scandir(dir)
    if not iterator then
      return
    end
    while true do
      local name, type = vim.loop.fs_scandir_next(iterator)
      if not name then
        break
      end

      if type == "directory" then
        local full_path = dir .. "/" .. name
        if M.is_project_dir(full_path, options) then
          table.insert(repos, string.sub(full_path, #ws_dir + 2))
        elseif M.is_venv_dir(full_path) then
          -- do nothing
        else
          scan_dir(full_path, depth + 1)
        end
      end
    end
  end

  scan_dir(ws_dir, 0)
  return repos
end

M.update_opened_projects = function(results, budget)
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local tabcwd = vim.fn.getcwd(-1, tabnr)
    -- print("tab", tabnr, tabcwd)
    local project = results[tabcwd]
    if project ~= nil then
      project["tabnr"] = tabnr
      budget = budget - 1
    end
  end
  return budget
end

M.sort_projects = function(a, b)
  local va, vb

  va = (a.tabnr ~= nil) and a.tabnr or 100
  vb = (b.tabnr ~= nil) and b.tabnr or 100
  if va ~= vb then
    return va < vb
  end

  va = a.recent or "1111-11-11"
  vb = b.recent or "1111-11-11"
  if va ~= vb then
    return va > vb
  end

  va = a.ws_name
  vb = b.ws_name
  if va ~= vb then
    return va < vb
  end

  va = a.proj_relpath
  vb = b.proj_relpath
  if va ~= vb then
    return va < vb
  end
end

M.find = function(options)
  local max_wlen = 5
  local max_plen = 20
  local results = {}
  for ws_name, ws_dir in pairs(options.workspaces) do
    if max_wlen < #ws_name then
      max_wlen = #ws_name
    end
    local ws_abspath = vim.fn.fnamemodify(ws_dir, ":p"):gsub("/+$", "")
    for _, proj_relpath in ipairs(M.find_repos(ws_abspath, options)) do
      if max_plen < #proj_relpath then
        max_plen = #proj_relpath
      end
      local proj_abspath = ws_abspath
      if proj_relpath ~= "" then
        proj_abspath = proj_abspath .. "/" .. proj_relpath
      end
      results[proj_abspath] = {
        ws_name = ws_name,
        ws_abspath = ws_abspath,
        proj_relpath = proj_relpath,
        proj_abspath = proj_abspath,
      }
    end
  end
  local budget = options.recent_max
  budget = M.update_opened_projects(results, budget)
  budget = require("projects.recent").load(results, budget)
  results = vim.tbl_values(results)
  table.sort(results, M.sort_projects)
  -- print("results", vim.inspect(results))
  return results, max_wlen, max_plen
end

return M
