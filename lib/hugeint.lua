-- hugeint library from fghlib (https://github.com/fghsgh/fghlib)
-- written by fghsgh and released under the GPL
-- compatible with Lua 5.2 and Lua 5.3

local math = require("math")
local string = require("string")

local hugeint = {}

local private = {} -- will be used for private fields in tables

local function printh(h)
  require("io").write(("{\n  data = %q,\n  sign = %s\n}\n"):format(h[private].data,h[private].sign))
end

-- throws an error with a message describing a bad argument type
local function errorarg(n,exp,got,lvl) -- n = number of argument, exp = expected type, got = gotten type, lvl = error level
  error("bad argument #" .. tostring(n) .. ": " .. exp .. " expected, got " .. got,3 + (lvl or 0))
end

-- make a new hugeint, given data string and sign
local function create(data,sign)
  return setmetatable({
    [private] = {
      data = data,
      sign = sign
    }
  },hugeint.meta)
end

-- removes leading zeroes of a hugeint
local function trim(n)
  while n[private].data:byte(-1,-1) == 0 do
    n[private].data = n[private].data:sub(1,-2)
  end
  return n
end

-- converts a string into a hugeint
local function stringtohugeint(s,base)
  if not base then
    base = 10
  end

  local sign = s:sub(1,1) == "-"
  local result = create("",false)
  local digit = create("\1",false)

  for i=s:len(),sign and 2 or 1,-1 do
    local b = s:byte(i,i)
    if ("0"):byte() <= b and b <= ("9"):byte() then
      b = b - ("0"):byte()
      if b >= base then
        return nil
      end
      result = result + digit * b
    elseif ("A"):byte() <= b and b <= ("Z"):byte() then
      b = b - ("A"):byte() + 10
      if b >= base then
        return nil
      end
      result = result + digit * b
    elseif ("a"):byte() <= b and b <= ("z"):byte() then
      b = b - ("a"):byte() + 10
      if b >= base then
        return nil
      end
      result = result + digit * b
    else
      return nil
    end
    digit = digit * base
  end

  return sign and -result or result
end

-- checks if the arguments are two hugeints and converts them to hugeints if possible, also clones the hugeints
local function checkarg(a,b)
  if type(a) == "number" then
    a = hugeint.create(a)
  elseif type(a) == "string" then
    a = stringtohugeint(a)
  end
  if type(b) == "number" then
    b = hugeint.create(b)
  elseif type(b) == "string" then
    b = stringtohugeint(b)
  end

  if not hugeint.ishugeint(a) then
    errorarg(1,"hugeint",type(a),1)
  end
  if not hugeint.ishugeint(b) then
    errorarg(2,"hugeint",type(b),1)
  end

  return create(a[private].data,a[private].sign),create(b[private].data,b[private].sign)
end

-- left shift a once and append carry to the end
local function lshift(a,carry)
  if not carry then
    carry = 0
  end
  for i=1,a[private].data:len() do
    local b = a[private].data:byte(i,i) * 2 + carry
    if b >= 256 then
      carry = 1
      b = b - 256
    else
      carry = 0
    end
    a[private].data = a[private].data:sub(1,i - 1) .. string.char(b) .. a[private].data:sub(i + 1,-1)
  end
  if carry == 1 then
    a[private].data = a[private].data .. "\1"
  end
end

--[[
This algorithm is what was used on 8-bit CPUs that couldn't do division natively
variables: a,b,dividend,result
`a` and `b` are arguments (we want to calculate `a`/`b`
`dividend` and `result` are 0
for each bit of `a`, starting from the left:
  take said bit of `a` and append it to the right of `dividend`, left shifting dividend in the process
  if `b` is smaller or equal to `dividend`, subtract `b` from `dividend`
  if the subtraction occured, left shift `result` and add one
  otherwise, left shift `result` without adding one
`result`=`a`/`b`, `dividend`=`a`%`b`
]]
local function div(a,b)
  a,b = checkarg(a,b)

  if b == create("",false) then
    error("divide by zero",3) -- 1 is div(), 2 is some hugeint function, 3 is whatever called that
  end

  -- check for negative numbers
  if (a[private].sign or b[private].sign) and not(a[private].sign and b[private].sign) then
    a,b = a:abs(),b:abs()
    local result,mod = div(a,b)
    if mod ~= create("",false) then
      return -(1 + result),b - mod
    else
      return -result,mod
    end
  end

  -- create variables as described in the algorithm above
  local dividend = hugeint.create(0)
  local result = hugeint.create(0)

  -- for each byte of a, from MSB to LSB
  for i=a[private].data:len(),1,-1 do
    local byte = a[private].data:byte(i,i)
    -- for each bit of said byte
    for i=1,8 do
      -- extract the bit
      local carry = byte >= 128 and 1 or 0
      byte = byte * 2 % 256

      -- append it to dividend
      lshift(dividend,carry)

      -- check if dividend >= b
      if dividend >= b then
        dividend = dividend - b
	lshift(result,1)
      else
        lshift(result,0)
      end
    end
  end

  return trim(result),trim(dividend)
end

function hugeint.abs(n)
  if not hugeint.ishugeint(n) then
    errorarg(1,"hugeint",type(n))
  end

  return create(n[private].data,false)
end

function hugeint.create(n)
  if type(n) == "number" then
    local sign = n < 0
    local data = ""

    n = math.abs(math.floor(n))
    while n > 0 do
      data = data .. string.char(n % 256)
      n = (n - n % 256) / 256
    end

    return create(data,sign)
  elseif type(n) == "string" then
    return stringtohugeint(n,base)
  elseif hugeint.ishugeint(n) then
    trim(n)
    return create(n[private].data,n[private].sign)
  else
    errorarg(1,"number",type(n))
  end
end

function hugeint.div(a,b)
  return div(a,b)
end

--TODO
function hugeint.format()
end

function hugeint.ishugeint(h)
  return type(h) == "table" and not not rawget(h,private)
end

-- This is a port of my routine at https://www.omnimaga.org/asm-language/(z80)-32-bit-by-16-bits-division-and-32-bit-square-root/msg406929/#msg406929
-- I have the full permission to copy this algorithm, as I was the author of that one as well.
-- It's kind of weird decompiling your own routine after half a year.
function hugeint.sqrt(n)
  if not hugeint.ishugeint(n) then
    errorarg(1,"hugeint",type(n))
  end

  if n[private].sign and n ~= create("",false) then
    error("attempt to calculate square root of negative hugeint",2)
  end

  local result = hugeint.create(0)
  local remainder = hugeint.create(0)

  for i=n[private].data:len(),1,-1 do
    local b = n[private].data:byte(i,i)
    for i=1,4 do
      -- get next 2 bits
      b = b * 4
      local bits = math.floor(b / 256)
      b = b % 256

      for i=1,remainder[private].data:len() do
        local b = remainder[private].data:byte(i,i) * 4 + bits
	bits = math.floor(b / 256)

	remainder[private].data = remainder[private].data:sub(1,i - 1) .. string.char(b % 256) .. remainder[private].data:sub(i + 1,-1)
      end
      if bits ~= 0 then
        remainder[private].data = remainder[private].data .. string.char(bits)
      end

      -- multiply result by 2
      result = result + result -- this is faster than * 2

      if remainder >= result then
        remainder = remainder - result
	result = result + 2
      end
    end
  end

  return result / 2
end

function hugeint.tonumber(n)
  if not hugeint.ishugeint(n) then
    return nil
  end

  local result = 0
  for i=n[private].data:len(),1,-1 do
    result = result * 256 + n[private].data:byte(i,i)
  end

  if n[private].sign then
    return -result
  else
    return result
  end
end

hugeint.meta = {}

function hugeint.meta.__add(a,b)
  a,b = checkarg(a,b) -- check if we have two hugeints or numbers convertible to hugeints

  if a[private].sign then
    return b - (-a)
  end
  if b[private].sign then
    return a - (-b)
  end

  while a[private].data:len() < b[private].data:len() do
    a[private].data = a[private].data .. "\0"
  end
  while a[private].data:len() > b[private].data:len() do
    b[private].data = b[private].data .. "\0"
  end

  local result = ""
  local carry = 0
  for i=1,a[private].data:len() do
    local b = a[private].data:byte(i,i) + b[private].data:byte(i,i) + carry
    if b >= 256 then
      carry = 1
      b = b - 256
    else
      carry = 0
    end
    result = result .. string.char(b)
  end
  if carry > 0 then
    result = result .. "\1"
  end

  return trim(create(result,false))
end

function hugeint.meta.__sub(a,b)
  a,b = checkarg(a,b)

  if a[private].sign then
    return -(-a + b)
  end
  if b[private].sign then
    return a + (-b)
  end
  if a < b then
    return - (b - a)
  end

  while a[private].data:len() < b[private].data:len() do
    a[private].data = a[private].data .. "\0"
  end
  while a[private].data:len() > b[private].data:len() do
    b[private].data = b[private].data .. "\0"
  end

  local result = ""
  local carry = 0
  for i=1,a[private].data:len() do
    local b = a[private].data:byte(i,i) - b[private].data:byte(i,i) - carry
    if b < 0 then
      carry = 1
      b = b + 256
    else
      carry = 0
    end
    result = result .. string.char(b)
  end

  return trim(create(result,false))
end

function hugeint.meta.__mul(a,b)
  a,b = checkarg(a,b)

  if (a[private].sign or b[private].sign) and not(a[private].sign and b[private].sign) then
    return -(-a * b)
  end

  local fullresult = ""
  for i=1,b[private].data:len() do
    local result = ""
    local carry = 0
    for j=1,a[private].data:len() do
      local b = a[private].data:byte(j,j) * b[private].data:byte(i,i) + carry
      carry = (b - b % 256) / 256
      result = result .. string.char(b % 256)
    end
    if carry > 0 then
      result = result .. string.char(carry)
    end
  
    while fullresult:len() < result:len() + i - 1 do
      fullresult = fullresult .. "\0"
    end
    while fullresult:len() > result:len() + i - 1 do
      result = result .. "\0"
    end

    local carry = 0
    for j=1,result:len() do
      local b = result:byte(j + i - 1) + fullresult:byte(j) + carry
      if b >= 256 then
        carry = 1
	b = b - 256
      else
        carry = 0
      end
      fullresult = fullresult:sub(1,j - 1) .. string.char(b) .. fullresult:sub(j + 1,-1)
    end

    return trim(create(fullresult,false))
  end

  return trim(create(result .. string.char(carry),false))
end

function hugeint.meta.__div(a,b)
  return (div(a,b)) -- only return the first result
end

function hugeint.meta.__mod(a,b)
  return ({div(a,b)})[2] -- only return the second result
end

function hugeint.meta.__pow(a,b)
  a,b = checkarg(a,b)

  if b < 0 then
    return hugeint.create(0)
  end

  local result = hugeint.create(1)

  for i=1,b[private].data:len() do
    local b = b[private].data:byte(i,i)
    for j=1,8 do
      if b % 2 == 1 then
	b = b - 1
        result = result * a
      end
      b = b / 2
      a = a * a
    end
  end

  return trim(result)
end

function hugeint.meta.__unm(a)
  a = checkarg(a,create("",false))

  return trim(create(a[private].data,not a[private].sign))
end

function hugeint.meta.__concat(a,b)
  return tostring(a) .. tostring(b)
end

function hugeint.meta.__len(a)
  a = checkarg(a,create("",false))

  error("attempt to get length of a hugeint value",2)
end

function hugeint.meta.__eq(a,b)
  if hugeint.ishugeint(a) and hugeint.ishugeint(b) then
    trim(a)
    trim(b)
    if a[private].data:len() == 0 and b[private].data:len() == 0 then
      return true
    elseif a[private].sign == b[private].sign and a[private].data == b[private].data then
      return true
    else
      return false
    end
  else
    return false
  end
end

function hugeint.meta.__le(a,b)
  a,b = checkarg(a,b)
  trim(a)
  trim(b)

  if a[private].sign ~= b[private].sign then
    return a[private].sign
  elseif a[private].data:len() ~= b[private].data:len() then
    return a[private].data:len() < b[private].data:len()
  else
    for i=a[private].data:len(),1,-1 do
      local a,b = a[private].data:byte(i,i),b[private].data:byte(i,i)
      if a ~= b then
        return a < b
      end
    end
    return true
  end
end

function hugeint.meta.__lt(a,b)
  a,b = checkarg(a,b)
  trim(a)
  trim(b)

  if a[private].sign ~= b[private].sign then
    return a[private].sign
  elseif a[private].data:len() ~= b[private].data:len() then
    return a[private].data:len() < b[private].data:len()
  else
    for i=a[private].data:len(),1,-1 do
      local a,b = a[private].data:byte(i,i),b[private].data:byte(i,i)
      if a ~= b then
        return a < b
      end
    end
    return false
  end
end

hugeint.meta.__index = hugeint

function hugeint.meta.__call()
  error("attempt to call a hugeint value",2)
end

function hugeint.meta.__ipairs()
  error("bad argument #1 to 'ipairs' (table expected, got hugeint)",2)
end

function hugeint.meta.__pairs()
  error("bad argument #1 to 'pairs' (table expected, got hugeint)",2)
end

function hugeint.meta.__tostring(n)
  if not hugeint.ishugeint(n) then
    error("bad argument #1 to 'tostring' (hugeint expected, got " .. type(n) .. ")",2)
  end

  local a,b = trim(create(n[private].data,false)),hugeint.create(10)
  local result = ""

  while a > 0 do
    local d,mod = a:div(b)
--[[
    io.write("a: ") printh(a)
    io.write("b: ") printh(b)
    io.write("d: ") printh(d)
    io.write("mod: ") printh(mod)
    do return "a" end
--]]

    a = d
    result = string.char(mod:tonumber() + ("0"):byte()) .. result
  end

  if n == hugeint.create(0) then
    return "0"
  elseif n[private].sign then
    return "-" .. result
  else
    return result
  end
end

function hugeint.meta.__idiv(a,b)
  return (div(a,b)) -- only return the first result
end

function hugeint.meta.__band(a,b)
  a,b = checkarg(a,b)

  while a[private].data:len() < b[private].data:len() do
    a[private].data = a[private].data .. "\0"
  end
  while a[private].data:len() > b[private].data:len() do
    b[private].data = b[private].data .. "\0"
  end

  local acarry,bcarry = 1,1
  local result = ""

  for i=1,a[private].data:len() do
    local ba,bb = a[private].data:byte(i,i),b[private].data:byte(i,i) -- ba,bb = one byte of a,b
    -- apply two's complement
    if a[private].sign then
      ba = 255 - ba + acarry
      if ba >= 256 then
	acarry = 1
        ba = ba - 256
      else
        acarry = 0
      end
    end

    if b[private].sign then
      bb = 255 - bb + acarry
      if bb >= 256 then
	bcarry = 1
        bb = bb - 256
      else
        bcarry = 0
      end
    end

    local br = 0 -- br = one byte of the result
    for i=1,8 do
      ba,bb = ba * 2,bb * 2
      local wa,wb
      if ba >= 256 then
        wa = true
	ba = ba - 256
      end
      if bb >= 256 then
        wb = true
	bb = bb - 256
      end

      br = br * 2
      if wa and wb then
        br = br + 1
      end
    end

    -- apply two's complement
    if a[private].sign and b[private].sign then
      br = 255 - br + rcarry
      if br >= 256 then
        rcarry = 1
        br = br - 256
      else
        rcarry = 0
      end
    end

    -- append br to result
    result = result .. string.char(br)
  end
end

--TODO
function hugeint.meta.__bor(a,b)
end

--TODO
function hugeint.meta.__bxor(a,b)
end

--TODO
function hugeint.meta.__bnot(a)
end

--TODO
function hugeint.meta.__lshift(a,b)
end

--TODO
function hugeint.meta.__rshift(a,b)
end

return hugeint
