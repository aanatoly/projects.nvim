local M = {}

M.filename = vim.fn.stdpath "cache" .. "/" .. "recent-projects.txt"

local t = os.date "%FT%T"
print(vim.inspect(t))

M.update = function(path, limit)
  local file = io.open(M.filename, "r")
  if not file then
    print("Error: Could not open file " .. M.filename)
    return
  end
  local recent = { path .. " " .. os.date "%FT%T" }
  for line in file:lines() do
    if limit <= 1 then
      break
    end
    if line:sub(1, 1) == "/" and line:sub(1, #path) ~= path then
      table.insert(recent, line)
      limit = limit - 1
    end
  end
  file:close()

  file = io.open(M.filename, "w")
  if not file then
    print("Error: Could not write to file " .. M.filename)
    return
  end
  for _, line in ipairs(recent) do
    file:write(line .. "\n")
  end
  file:close()
end

M.get = function()
  local function validate_results(line)
    local m = { string.match(line, "^(%S+)%s+(%S+)") }
    if #m ~= 2 then
      return
    end
    return m
  end

  local recent = {}
  local file = io.open(M.filename, "r")
  if not file then
    print("Error: Could not open file " .. M.filename)
    return recent
  end
  for line in file:lines() do
    local r = validate_results(line)
    if r ~= nil then
      table.insert(recent, r)
    end
  end
  file:close()
  return recent
end

M.load = function(results, budget)
  local function update_results(m)
    local project = results[m[1]]
    if project == nil then
      return false
    end
    if project["tabnr"] ~= nil then
      return false
    end
    project["recent"] = m[2]
    return true
  end

  if budget < 1 then
    return budget
  end

  local recent = M.get()
  print("recent", vim.inspect(recent))
  for _, r in ipairs(recent) do
    if update_results(r) then
      budget = budget - 1
    end
    if budget < 1 then
      break
    end
  end
  return budget
end

return M
