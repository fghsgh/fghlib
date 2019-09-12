-- complex library from fghlib (https://github.com/fghsgh/fghlib)
-- written by fghsgh and released under the GPL
-- compatible with Lua 5.2 and Lua 5.3

local math = require("math")
local string = require("string")

local complex = {}
complex.meta = {}

local private = {} -- will be used for private fields in tables

-- throws an error with a message describing a bad argument type
local function errorarg(n,exp,got,lvl) -- n = number of argument, exp = expected type, got = gotten type, lvl = error level
  error("bad argument #" .. tostring(n) .. ": " .. exp .. " expected, got " .. got,3 + (lvl or 0))
end

-- make a new complex, given data string and sign
local function create(real,imag)
  return setmetatable({
    [private] = {
      real = real,
      imag = imag
    }
  },complex.meta)
end

-- checks if the arguments are two complexes and converts them to complexes if possible, also clones the complexes
local function checkarg(a,b)
  if type(a) == "number" then
    a = complex.create(a)
  elseif type(a) == "string" then
    if tonumber(a) then
      a = complex.create(tonumber(a))
    end
  end
  if type(b) == "number" then
    b = complex.create(b)
  elseif type(b) == "string" then
    if tonumber(b) then
      b = complex.create(tonumber(b))
    end
  end

  if not complex.iscomplex(a) then
    errorarg(1,"complex",type(a),1)
  end
  if not complex.iscomplex(b) then
    errorarg(2,"complex",type(b),1)
  end

  return create(a[private].real,a[private].imag),create(b[private].real,b[private].imag)
end

function complex.abs(c)
  if not complex.iscomplex(c) then
    errorarg(1,"complex",type(c))
  end

  return math.sqrt(c[private].real * c[private].real + c[private].imag * c[private].imag)
end

function complex.acos(c)
  c = checkarg(c,0)

  c = (c + (c * c - 1):sqrt()):log()
  return create(c[private].imag,-c[private].real)
end

function complex.angle(c)
  c = checkarg(c,0)

  if c[private].imag == 0 then
    return c[private].real >= 0 and 0 or math.pi
  else
    return ((c[private].real >= 0 and math.pi or 0) + math.atan(c[private].imag / c[private].real)) % (2 * math.pi) - math.pi
  end
end

function complex.asin(c)
  c = checkarg(c,0)

  c = (create(-c[private].imag,c[private].real) + (1 - c * c):sqrt()):log()
  return create(c[private].imag,-c[private].real)
end

function complex.atan(c)
  c = checkarg(c,0)

  c = create(1 + c[private].imag,-c[private].real) - create(1 - c[private].imag,c[private].real)
  return create(-c[private].imag / 2,c[private].real / 2)
end

function complex.conj(c)
  c = checkarg(c,0)

  return create(c[private].real,-c[private].imag)
end

function complex.cos(c)
  c = checkarg(c,0)

  return (create(-c[private].imag,c[private].real):exp() + create(c[private].imag,-c[private].real):exp()) / 2
end

function complex.create(real,imag,polar)
  if tonumber(real) then
    real = tonumber(real)
  else
    errorarg(1,"number",type(real))
  end

  if imag == nil then
    imag = 0
  elseif tonumber(imag) then
    imag = tonumber(imag)
  else
    errorarg(2,"number",type(imag))
  end

  if polar then
    real,imag = real * math.cos(imag),real * math.sin(imag)
  end

  return create(real,imag)
end

function complex.exp(c)
  return complex.create(math.exp(c[private].real),c[private].imag,true)
end

function complex.log(c,base)
  if not base then
    c = checkarg(c,0)
    return create(math.log(c:abs()),c:angle())
  else
    c,base = checkarg(c,base)
    return create(math.log(c:abs()),c:angle()) / create(math.log(base:abs()),base:angle())
  end
end

function complex.iscomplex(c)
  return type(c) == "table" and not not rawget(c,private)
end

function complex.sin(c)
  c = checkarg(c,0)

  return (create(-c[private].imag,c[private].real):exp() - create(c[private].imag,-c[private].real):exp()) / create(0,2)
end

function complex.sqrt(c)
  c = checkarg(c,0)

  return complex.create(math.sqrt((c:abs() + c[private].real) / 2),(c[private].imag < 0 and -1 or 1) * math.sqrt((c:abs() - c[private].real) / 2))
end

function complex.tan(c)
  c = checkarg(c,0)

  return c:sin() / c:cos()
end

complex.i = complex.create(0,1)

function complex.meta.__add(a,b)
  a,b = checkarg(a,b)

  return create(a[private].real + b[private].real,a[private].imag + b[private].imag)
end

function complex.meta.__sub(a,b)
  a,b = checkarg(a,b)

  return create(a[private].real - b[private].real,a[private].imag - b[private].imag)
end

function complex.meta.__mul(a,b)
  a,b = checkarg(a,b)

  return create(a[private].real * b[private].real - a[private].imag * b[private].imag,a[private].real * b[private].imag + a[private].imag * b[private].real)
end

function complex.meta.__div(a,b)
  a,b = checkarg(a,b)

  local a_mul_conjb = a * b:conj()
  return create(a_mul_conjb[private].real / (b[private].real * b[private].real + b[private].imag * b[private].imag),a_mul_conjb[private].imag / (b[private].real * b[private].real + b[private].imag * b[private].imag))
end

function complex.meta.__pow(a,b)
  a,b = checkarg(a,b)

  local r,a = a:abs(),a:angle()
  return (math.log(r) * b):exp() * create(-b[private].imag * a,b[private].real * a):exp()
end

function complex.meta.__unm(a)
  a = checkarg(a,0)

  return create(-a[private].real,-a[private].imag)
end

function complex.meta.__concat(a,b)
  return tostring(a) .. tostring(b)
end

function complex.meta.__len(a)
  error("attempt to get length of a complex value",2)
end

function complex.meta.__eq(a,b)
  if complex.iscomplex(a) and complex.iscomplex(b) then
    return a[private].real == b[private].real and a[private].imag == b[private].imag
  else
    return false
  end
end

function complex.meta.__le(a,b)
  error("attempt to compare complex values",2)
end

function complex.meta.__lt(a,b)
  error("attempt to compare complex values",2)
end

function complex.meta.__index(c,k)
  if complex[k] then
    return complex[k]
  elseif k == "real" then
    return c[private].real
  elseif k == "imag" then
    return c[private].imag
  else
    return nil
  end
end

function complex.meta.__newindex(c,k,v)
  if k == "real" then
    if tonumber(v) then
      c[private].real = tonumber(v)
    else
      errorarg(3,"number",type(v))
    end
  elseif k == "imag" then
    if tonumber(v) then
      c[private].imag = tonumber(v)
    else
      errorarg(3,"number",type(v))
    end
  else
    errorarg(2,"\"real\" or \"imag\"",(type(k) == "string" and ("%q"):format(k) or type(k)))
  end
end

function complex.meta.__call()
  error("attempt to call a complex value",2)
end

function complex.meta.__ipairs()
  error("bad argument #1 to 'ipairs' (table expected, got complex)",2)
end

function complex.meta.__pairs()
  error("bad argument #1 to 'pairs' (table expected, got complex)",2)
end

function complex.meta.__tostring(c)
  if not complex.iscomplex(c) then
    error("bad argument #1 to 'tostring' (complex expected, got " .. type(c) .. ")",2)
  end

  local real,imag = "",""
  if c[private].real ~= 0 then
    real = tostring(c[private].real)
  elseif c[private].imag == 0 then
    return "0"
  end

  if c[private].imag == 1 then
    imag = "i"
  elseif c[private].imag == -1 then
    imag = "-i"
  elseif c[private].imag ~= 0 then
    imag = tostring(c[private].imag) .. "i"
  end

  return real .. ((real:len() > 0 and c[private].imag > 0) and "+" or "") .. imag
end

return complex
