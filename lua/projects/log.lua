local M = {}

M.enabled = true

M.log = function(...)
  if M.enabled then
    print(...)
  end
end

return M
