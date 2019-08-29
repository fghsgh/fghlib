-- unicode library from fghlib (https://github.com/fghsgh/fghlib)
-- written by fghsgh and released under the GPL
-- warning: parts of this file require UTF-8 support
-- compatible with Lua 5.2 and Lua 5.3

local math = require("math")
local string = require("string")
local table = require("table")

local unidata = {} -- will be filled below function definitions

local unicode = {}

-- throws an error with a message describing a bad argument type
local function errorarg(n,exp,got) -- n = number of argument, exp = expected type, got = gotten type
  error("bad argument #" .. tostring(n) .. ": " .. exp .. " expected, got " .. got,3)
end

-- returns how many bits are needed to represent the given number in binary
local function bitwidth(n) -- n = the number
  local test = 1 -- which bit we are testing right now
  local i = 0 -- counts how many bits we have tested
  while n >= test do
    test = test * 2
    i = i + 1
  end
  return i
end

-- check whether the first byte of the given string is the first byte of a character
local function isFirstByte(s) -- s = the string
  local b = s:byte() -- b stands for byte
  if b < 0x80 or b >= 0xc0 then
    return true
  else
    return false
  end
end

-- strips the leading ones off the binary representation of the given 8-bit number, and also returns how many it stripped off
local function stripone(b) -- b = the number (it is 8-bit so b stands for byte)
  local result = 0
  local sub = 0x80 -- sub = what will be subtracted
  while b >= sub do
    b = b - sub
    sub = sub / 2
    result = result + 1
  end
  return result,b
end

-- same as stripone, but only returns the stripped number (for performance)
local function rstripone(b) -- exactly the same as stripone()
  local result = 0
  local sub = 0x80
  while b >= sub do
    b = b - sub
    sub = sub / 2
    result = result + 1
  end
  return b
end

-- returns the length of the first character, in bytes
local function charlen(s) -- s = the string of which to take the first character
  local b = s:byte() -- b stands for byte
  if b < 0x80 then
    return 1
  elseif b < 0xc0 then
    return 0
  else
    return (stripone(b)) -- only return first result from stripone()
  end
end

-- correct i and j as indices for s using the rules of string.sub(), with l being unicode.len(s)
local function subindex(l,i,j)
  if i < 0 then
    i = l + i + 1
  end
  if j < 0 then
    j = l + j + 1
  end
  if i < 1 then
    i = 1
  end
  if j > l then
    j = l
  end
  return i,j
end

-- returns Unicode codepoint for first character of s
local function code(s) -- s = the string
  local b = s:byte() -- b stands for byte
  if b < 0x80 then
    return b
  elseif b < 0xc0 then
    return 0
  else
    local nbits,result = stripone(b) -- nbits = the number of bits in the first number that marks the length of the character, and the number of bytes of the character
    for i=2,nbits do
      result = result * 64 + rstripone(s:byte(i,i))
    end
    return result
  end
end

-- convert string to either uppercase or lowercase
--TODO bugged
local function upperlower(s,from,to)
  local result = ""
  local i = 1
  local len = s:len()
  while i <= len do
    local charlen = charlen(s:sub(i,i))
    local b = unicode.byte(s:sub(i,i + charlen - 1))

    -- binary search main table
    local first,last = 1,#unidata.case
    local wassimple = false
    while first < last do
      local t = first + last
      t = (t - t % 2) / 2
      if unidata.case[t][from] > b then
        first = t + 1
      elseif unidata.case[t][from] + unidata.case[t].length <= b then
        last = t - 1
      else
        local relb = b - unidata.case[t][from]
        local chunklen = math.abs(unidata.case[t][from] - unidata.case[t][to])
	if chunklen < unidata.case[t].length then
	  relb = relb % (chunklen * 2)
	  if unidata.case[i][from] > unidata.case[i][to] then
	    if relb >= chunklen then
	      b = b - chunklen
	    end
	  else
	    if relb < chunklen then
	      b = b + chunklen
	    end
	  end
	else
	  b = b + unidata.case[t][from] - unidata.case[t][to]
	end
	wassimple = true
	break
	i = i + charlen
      end
    end

    -- seach exceptions
    if not wassimple then
      for j=1,#unidata.caseexcept do
        local k = i
	local match = true
        for l=1,unidata.caseexcept[j][from]:len() do
	  if s:sub(k,k) == unidata.caseexcept[j][from]:sub(l,l) then
	    k = k + 1
	  else
	    match = false
	    break
	  end
	end
	if match then
	  result = result .. unidata.caseexcept[j][to]
	  i = k + 1
	else
	  i = i + charlen
	end
      end
    end
    result = result .. unicode.char(b)
  end
  return result
end

function unicode.byte(s,i,j)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  if type(i) == "nil" then
    i = 1
  elseif type(i) ~= "number" then
    errorarg(2,"number",type(i))
  end
  if type(j) == "nil" then
    j = -1
  elseif type(j) ~= "number" then
    errorarg(3,"number",type(j))
  end
  i,j = subindex(unicode.len(s),i,j)
  local k = unicode.utfToStr(s,i) -- k is the third index variable

  local result = {}
  while i <= j do
    local len = charlen(s:sub(k,k))
    result[#result + 1] = code(s:sub(k,k + len - 1))
    i = i + 1
    k = k + len
  end
  return table.unpack(result)
end

function unicode.char(...)
  local args = {...}
  local result = ""
  for i=1,#args do
    local n = args[i] -- n stands for number (the codepoint of the character we want in unicode representation)
    if type(n) ~= "number" then
      errorarg(i,"number",type(n))
    end
    local width = bitwidth(n)
    if width <= 7 then
      result = result .. string.char(n)
    else
      local c = "" -- c stands for character
      local done = false
      while not done do
        if bitwidth(n) + c:len() <= 6 then -- the following operators are to compensate for Lua's lack of bitwise operators (5.3 does have them but we want 5.2-compatibility)
	  c = string.char(0xff - 2 ^ (7 - c:len()) + 1 + n) .. c
	  done = true
	else
	  c = string.char(0x80 + n % 0x40) .. c
	  n = (n - n % 0x40) / 0x40
	end
      end
      result = result .. c
    end
  end
  return result
end

function unicode.find(s,pattern,init,plain)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  if type(init) == "nil" then
    init = 1
  elseif type(init) ~= "number" then
    errorarg(3,"number",type(init))
  elseif init < 0 then
    init = unicode.len(s) + init + 1
  end
  -- string.find() will do all other type checks

  local a,b = s:find(pattern,unicode.utfToStr(s,init),plain)
  if a then
    return unicode.strToUTF(s,a),unicode.strToUTF(s,b)
  else
    return nil
  end
end

function unicode.len(s)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  local result = 0
  local i = 1
  local len = s:len()
  while i <= len do
    result = result + 1
    i = i + charlen(s:sub(i,i))
  end
  return result
end

function unicode.lower(s)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  return upperlower(s,"upper","lower")
end

function unicode.match(s,pattern,init)
  if type(init) == "nil" then
    init = 1
  elseif type(init) ~= "number" then
    errorarg(3,"number",type(init))
  elseif init < 0 then
    init = unicode.len(s) + init + 1
  end
  return s:match(pattern,unicode.utfToStr(init))
end

--TODO
function unicode.mode()
end

function unicode.reverse(s)
  local result = ""
  local i = 1
  while i <= #s do
    result = s:sub(i,i + charlen(s:sub(i,i)) - 1) .. result
    i = i + charlen(s:sub(i,i))
  end
  return result
end

function unicode.strToUTF(s,i)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  if type(i) ~= "number" then
    errorarg(2,"number",type(i))
  end
  local result = 0
  local j = 1
  while j <= i do
    j = j + charlen(s:sub(j,j))
    result = result + 1
  end
  return result
end

function unicode.sub(s,i,j)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  if type(i) ~= "number" then
    errorarg(2,"number",type(i))
  end
  if type(j) == "nil" then
    j = -1
  elseif type(j) ~= "number" then
    errorarg(3,"number",type(j))
  end
  i,j = subindex(unicode.len(s),i,j)
  i,j = unicode.utfToStr(s,i),unicode.utfToStr(s,j)
  j = j + charlen(s:sub(j,j)) - 1
  return s:sub(i,j)
end

function unicode.upper(s)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  return upperlower(s,"lower","upper")
end

function unicode.utfToStr(s,i)
  if type(s) ~= "string" then
    errorarg(1,"string",type(s))
  end
  if type(i) ~= "number" then
    errorarg(2,"number",type(i))
  end
  local result = 1
  for j=2,i do
    result = result + charlen(s:sub(result,result))
  end
  return result
end

--TODO
function unicode.wlen()
end

--[[
Syntax of this table:
Each element is a block of characters, they are sorted numerically and do not overlap
  - upper: start of the uppercase block
  - lower: start of the lowercase block
  - length: the total number of characters in the block
  If the upper and lower blocks overlap, with a difference of N characters between the respective starts of their blocks, it is assumed the characters are ordered like AaBbCcDdEeFfGgHhIi (for N=1), or ABCabcDEFdefGHIghi (for N=3)
]]
unidata.case = {
  { -- Basic Latin
    upper = 0x0041,
    lower = 0x0061,
    length = 0x001a
  },{ -- Latin-1 Supplement
    upper = 0x00c0,
    lower = 0x00e0,
    length = 0x0018
  },{ -- Latin-1 Supplement, after × (upper) and ÷ (lower)
    upper = 0x00d8,
    lower = 0x00f8,
    length = 0x0007
  },{ -- Latin Extended-A
    upper = 0x0100,
    lower = 0x0101,
    length = 0x38
  },{ -- Latin Extended-A, after ĸ
    upper = 0x0139,
    lower = 0x013a,
    length = 0x000f
  },{ -- Latin Extended-A, after ŉ
    upper = 0x014a,
    lower = 0x014b,
    length = 0x002d
  },{ -- Latin Extended-A, after Ÿ
    upper = 0x0179,
    lower = 0x017a,
    length = 0x0005
  },{ -- Latin Extended-B
    upper = 0x0182,
    lower = 0x0183,
    length = 0x0003
  },{ -- Latin Extended-B, Ƈ and ƈ
    upper = 0x0187,
    lower = 0x0188,
    length = 0x0001
  },{ -- Latin Extended-B, Ƌ and ƌ
    upper = 0x018b,
    lower = 0x018c,
    length = 0x0001
  },{
  }
}

-- single characters that have to be converted into multi-character capital letters or vice versa, or single-letter exceptions, which would break the binary tree search in the main table
-- if a single letter occurs more than once in this list, the first found one takes precedence
-- the main table always takes precedence over this
unidata.caseexcept = {
  {
    upper = "Ÿ",
    lower = "ÿ"
  },{
    upper = "Kʼ",
    lower = "ĸ"
  },{
    upper = "’N",
    lower = "’n"
  },{
    upper = "’N",
    lower = "ŉ"
  },{
    upper = "S",
    lower = "ſ"
  },{
    upper = "Ƀ",
    lower = "ƀ"
  },{
    upper = "Ɓ",
    lower = "ɓ"
  },{
    upper = "Ɔ",
    lower = "ɔ"
  },{
    upper = "Ɖ",
    lower = "ɖ"
  },{
    upper = "Ɗ",
    lower = "ɗ"
  },{
    upper = "Ǝ",
    lower = "ǝ"
  },{
    upper = "Ə",
    lower = "ə"
  },{
    upper = "Ɛ",
    lower = "ɛ"
  }
}

return unicode
