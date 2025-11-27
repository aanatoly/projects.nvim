local M = {}

M.enabled = false

M.log = function(...)
  if M.enabled then
    print(...)
  end
end

return M
