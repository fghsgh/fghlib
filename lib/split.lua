--[[
This library consists of a single function (not a table!):

Depending on the type of the second argument, the next arguments will be
understood differently. The returned value will always be a numeric table
containing a list of strings. An error will be thrown if any invalid arguments
are passed.

  - The second argument is a string: split(string,delim,plain,include,double):
    The string is split on every occurence of the substring delim. If plain is
    true, no pattern-matching will occur (otherwise, standard Lua patterns are
    used). If include is true, the delimiter will be included at the end of
    every part (except the last one of course). If double is true, any double
    occurences of a delimiter will be ignored. This will throw an error if both
    include and double are true.

  - The second argument is a number: split(string,chars,utf8):
    The string is split into equal substrings of chars characters. The last part
    may be shorter than the others. If utf8 is true, the character count will be
    UTF-8-aware. Behavior is undefined if the passed string is not UTF-8 valid.


In both cases, the first argument (a string) is split into multiple substrings,
which are returned as a table.

examples:
split("a  %sb c","%s")                  -> {"a","","%sb","c"}
split("a  %sb c","%s",true)             -> {"a  ","b c"}
split("a  %sb c","%s",false,true)       -> {"a "," ","b ","c"}
split("a  %sb c","%s",true,true)        -> {"a  %s","b c"}
split("a  %sb c","%s",false,false,true) -> {"a","b","c"}
split("a  %sb c",3)                     -> {"a  ","%sb"," c"}
]]

local string = require("string")

return function(s,a1,a2,a3,a4)
  if type(s) ~= "string" then
    error("invalid argument #1 passed to split: string expected, got " .. type(s))
  end

  local result = {}
  if type(a1) == "string" then
    local delim = a1
    local plain = a2
    local include = a3
    local double = a4

    if include and double then
      error("invalid combination of arguments #4 and #5 passed to split: cannot both be true")
    end

    local i = 1
    while i <= s:len() do
      local a,b = s:find(delim,i,plain)
      if not a then
	result[#result + 1] = s:sub(i,-1)
	return result
      end

      if not double or a > i then
	result[#result + 1] = s:sub(i,include and b or a - 1)
      end
      i = b + 1
    end

    if not double then
      result[#result + 1] = ""
    end
    return result

  elseif type(a1) == "number" then
    local chars = a1
    local utf8 = a2

    if chars % 1 > 0 or chars <= 0 then
      error("invalid number passed as argument #2 to split")
    end

    if utf8 then
      local i = 1
      while i <= s:len() do
        local j = i
	for c=1,chars do
	  if (j > s:len()) then
	    result[#result + 1] = s:sub(i,-1)
	    return result
	  end
	  local b = s:byte(j)
	  j = j + 1
	  while b >= 0xc0 do
	    b = (b - 0x80) * 2
	    j = j + 1
	  end
	end

	result[#result + 1] = s:sub(i,j - 1)
	i = j
      end
      return result
    else
      local i = 1
      while i <= s:len() do
        result[#result + 1] = s:sub(i,i + chars - 1)
	i = i + chars
      end
      return result
    end

    return {}

  else
    error("invalid type passed to split: string or number expected, got " .. type(s))
  end

end
