local log = require("projects.log").log
local uv = vim.loop

local M = {}

local function find_repos_in_dir(ws_abs_path, depth)
  local function is_project_dir(dir)
    if uv.fs_stat(dir .. "/.git") then
      return true
    end
  end

  ws_abs_path = ws_abs_path:gsub("/+$", "")
  if is_project_dir(ws_abs_path) then
    return { ws_abs_path }
  end
  local repos = {}

  local function scan_dir(sdir, ldepth)
    if ldepth == 0 then
      return
    end

    local iterator = uv.fs_scandir(sdir)
    if not iterator then
      return
    end
    while true do
      local name, type = uv.fs_scandir_next(iterator)
      if not name then
        break
      end

      if type == "directory" then
        local full_path = sdir .. "/" .. name
        if is_project_dir(full_path) then
          table.insert(repos, full_path)
        else
          scan_dir(full_path, ldepth - 1)
        end
      end
    end
  end

  scan_dir(ws_abs_path, depth)
  return repos
end

local function find_repos(wss, depth)
  local repos = {}
  for ws_name, ws_path in pairs(wss) do
    local ws_abs_path = vim.fn.fnamemodify(ws_path, ":p")
    for _, repo_abs_path in ipairs(find_repos_in_dir(ws_abs_path, depth)) do
      repos[repo_abs_path] = {
        ws_name = ws_name,
        proj_abs_path = vim.fn.fnamemodify(repo_abs_path, ":~"):gsub("/+$", ""),
        proj_rel_path = repo_abs_path:sub(#ws_abs_path + 1),
      }
    end
  end
  return repos
end

local function upd_repos_tabnr(repos)
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local tabcwd = vim.fn.getcwd(-1, tabnr)
    if repos[tabcwd] then
      repos[tabcwd].tabnr = tabnr
    end
  end
end

local function path_tree_build(projects)
  local tree = {}

  for _, p in ipairs(projects) do
    local parts = vim.split(vim.fn.fnamemodify(p, ":p"), "/", { trimempty = true })
    local node = tree

    for _, part in ipairs(parts) do
      if not node[part] then
        node[part] = {}
      end
      node = node[part]
    end
    node.__is_project = p:gsub("/+$", "")
  end

  return tree
end

local function path_tree_find(tree, file)
  local parts = vim.split(vim.fn.fnamemodify(file, ":p"), "/", { trimempty = true })
  local node = tree

  for _, part in ipairs(parts) do
    node = node[part]
    if not node then
      return false
    end
    if node.__is_project then
      return node.__is_project
    end
  end

  return false
end

local function upd_repos_recency(repos, max_recent)
  local tree = path_tree_build(vim.tbl_keys(repos))
  for i, file in ipairs(vim.v.oldfiles) do
    local rc = path_tree_find(tree, file)
    if rc and repos[rc] and not repos[rc].recency then
      repos[rc].recency = i
      max_recent = max_recent - 1
      if max_recent == 0 then
        return
      end
    end
  end
end

local function sort_repos(a, b)
  local va, vb

  va = (a.tabnr ~= nil) and a.tabnr or 100
  vb = (b.tabnr ~= nil) and b.tabnr or 100
  if va ~= vb then
    return va < vb
  end

  va = a.recency or 1000
  vb = b.recency or 1000
  if va ~= vb then
    return va < vb
  end

  va = a.ws_name
  vb = b.ws_name
  if va ~= vb then
    return va < vb
  end

  va = a.proj_rel_path
  vb = b.proj_rel_path
  if va ~= vb then
    return va < vb
  end
end

M.get_repos = function(workspaces, depth, max_recent)
  local start = uv.hrtime()
  local repos = find_repos(workspaces, depth)
  upd_repos_tabnr(repos)
  upd_repos_recency(repos, max_recent)
  local elapsed_ms = (uv.hrtime() - start) / 1e6
  log(string.format("Repos scan: elapsed %.2f ms, num %d", elapsed_ms, #vim.tbl_keys(repos)))

  start = uv.hrtime()
  repos = vim.tbl_values(repos)
  table.sort(repos, sort_repos)
  elapsed_ms = (uv.hrtime() - start) / 1e6
  log(string.format("Repos sort: elapsed %.2f ms, num %d", elapsed_ms, #repos))

  return repos
end

return M
