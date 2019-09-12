local debug = require("debug")

local debug2 = {}

function debug2.getenv(f,name)
  local i = 1
  repeat
    local n,v = debug.getupvalue(f,i)
    if n == name then
      return v
    end
    i = i + 1
  until not n
end

function debug2.listenv(f)
  local i = 0
  return function()
    i = i + 1
    return debug.getupvalue(f,i)
  end
end

function debug2.reload(module)
  package.loaded[module] = nil
  return require(module)
end

return debug2
