# fghlib
This is a collection of pure Lua libraries, for those of you who don't want to install C libraries and/or don't have root access. Please note that using these can be a lot slower than using C implementations.

All of these are written for Lua 5.2, but also work on Lua 5.3 unless stated otherwise.

All of these work on most Linux installations. On Windows, I can only guarantee that the ones with `(no dependencies)` will work (and those with only other dependencies from this collection of libraries).

### Contributing
These libraries are distributed under the GPL. Please read [my code style](style.md) before contributing. Also, sometimes I use some quirky properties of Lua, so a full read of the [Reference Manual](https://www.lua.org/manual/5.2/) is recommended.

## Installation
Download all libraries from the [lib directory](lib) that you want, plus their dependencies, if any. Put the downloaded libraries in any directory of your Lua path. Check your path using `=package.path` in the Lua interpreter. You can change the Lua path by changing the `LUA_PATH` environment variable as defined in the [Lua Reference Manual](https://www.lua.org/manual/5.2/manual.html#pdf-package.path).

Load a library using `local NAME = require("NAME")`. You can also run the file using `dofile()`, but if you use the `dofile()` method more than once, undefined behaviour may occur, for example in this piece of code:
```lua
local complex1 = dofile("complex.lua")
local complex2 = dofile("complex.lua")

print(complex1.i * complex2.i)
-- throws error "bad argument #2: complex expected, got table"
```
The above happened because `complex.i` is a table with a metatable. Now, `complex1.i` and `complex2.i` have different metatables and a different `private` field, which makes them distinct. `complex1` can only work with other `complex1` types, not with `complex2`. Therefore, it wasn't recognized as a complex number, but as a table (which it, in fact, is).

## Currently implemented
- `complex`: complex number type (no dependencies) [(documentation)](#complex)
- `debug2`: an interface to the standard `debug` library for use in the Lua interpreter (no dependencies) [(documentation)](#debug2)
- `hugeint`: infinite-width integers, implemented using binary strings and metatables (no dependencies) [(documentation)](#hugeint)
- `unicode`: UTF-8 port of the string library, using the string library (no dependencies) [(documentation)](#unicode)

## Planned
- `data`: deflate/inflate, CRC, SHA... (no dependencies)
- `fs`: more filesystem functionality, like reading directories, getting/setting permissions, modified dates, creating directories, removing files... (needs the standard UNIX programs and `io.popen()`)
- `http`: HTTP GET/POST using CURL (needs CURL and `io.popen()`)
- `parallel`: running multiple Lua functions simultaneously, through the use of the coroutine library and a hack using garbage collection and metatables. This is not real multithreading, though (no dependencies)
- `quat`: quaternion number type (no dependencies)
- `regex`: regular expressions (standard, extended, and Perl) (no dependencies)
- `shell`: running shell commands with escaped arguments and POSIX-compliant getopt (no dependencies)
- `term`: ncurses-like library (needs the `stty` program, `termcap`, `unicode`, and `io.popen()`)
- `termcap`: termcap reader, this can do basic stuff like setting the text color or cursor position (needs the termcap database)
- `xml`: XML parsing (no dependencies)

The full list of libraries with no dependencies: `complex`, `data`, `debug2`, `hugeint`, `quat`, `regex`, `unicode`, `xml`.


## Planned example programs
- `bigcalc`: big integer calculator (uses `hugeint`)
- `cpxcalc`: complex number calculator (uses `complex`)
- `edit`: a simple text editor (uses `shell`, `term`)
- `fetch`: send a GET request and write the output to stdout (uses `http`)
- `lua`: a Lua interpreter with syntax highlighting and tab autocompletion (uses `regex`, `shell`, `term`, `unicode`)
- `search`: search the content of files for a regex (uses `regex`, `shell`)


## Library documentation
This is not on a wiki because this repository was originally private and I didn't have premium.

### `complex`
A complex number can be indexed using the keys `"real"` and `"imag"` to read and change the real and imaginary components, but setting them can throw an error if the assigned value is not a number.

One note is that when the `^` operator is used to calculate roots, the primary root is returned.

#### Methods
`complex.abs(c):number`\
Calculates the absolute value of the given complex number.

`complex.acos(c):complex`\
Calculates the arc cosine of the given complex number.

`complex.angle(c):number`\
Returns the angle between the given complex number and the positive real axis, in radians. This angle is in the interval ]-π,π]. `0` is returned for `0`.

`complex.asin(c):complex`\
Calculates the arc sine of the given complex number.

`complex.conj(c):complex`\
Returns the complex conjugate of the given complex number.

`complex.cos(c):complex`\
Calculates the cosine of the given complex number.

`complex.create(real,imag,polar):complex`\
Creates a complex number from a real part and an imaginary part. If `polar` is true, the number is given in polar form. That is, `real` is the absolute value, and `imag` is the angle in radians. `imag` defaults to `0`, `polar` defaults to `false`.

`complex.exp(c):complex`\
Raises the mathematical constant `e` to the power of the given complex number.

`complex.i`\
Equal to the value of `i`.

`complex.iscomplex(c):boolean`\
Returns whether the given value is a complex number or not.

`complex.log(c,base):c`\
Returns the principal logarithm of `c` with base `base`. `base` defaults to the mathematical constant `e`.

`complex.meta`\
The metatable used for the complex number type. This metatable implements all arithmetic operations except for `%` and `//` (Lua 5.3 only). Indexing can be used to both access the `complex` library's table, and to access the real and imaginary parts of the number.

`complex.sin(c):complex`\
Calculates the sine of the given complex number.

`complex.sqrt(c):complex`\
Calculates one of the square roots of the given complex number. The returned square root is the one with a positive real component.

`complex.tan(c):complex`\
Calculates the tangent of the given complex number.

#### Planned features
- `complex.atan(c):complex`: it is already implemented, but doesn't work.
- Hyperbolic trigonometry functions

### `debug2`

#### Methods
`debug2.getenv(f,name):any`\
Gets the environment variable of the given function with the given name.

`debug2.listenv(f):f`\
Returns an iterator over all environment variables of the given function.

`debug2.reload(name):any`\
Unloads the given module name, then requires it again and returns the result.

#### Planned features
- Stepping line-by-line through threads, without having to deal with hooks.
- Getting/setting local variables at the current point of execution.

### `hugeint`
This library simulates the creation of a new type called `hugeint`. This is an infinite-width integer. It overloads all standard operators to handle hugeints just like regular numbers. Hugeints are stored internally as a table with a private field, which can only be accessed by means of the `next()` function, because this function, sadly, doesn't care about metatables.

#### Methods
`hugeint.abs(hugeint):hugeint`\
Returns the absolute value of the given `hugeint`.

`hugeint.create(number,base):hugeint`\
Creates a hugeint out of the given number. If it is not a whole number, it is rounded towards negative infinity. The input can also be a string, but in that case, it must represent a whole number. It can start with a `-` though. The string will not be converted to a number before being converted to a hugeint. The string can be in a different base, just like with `tonumber()`. In that case, the base is assumed to be `base`. If `number` is a hugeint, a copy of it is returned.

`hugeint.div(a,b):hugeint,hugeint`\
Performs an integer division and returns both the result and the remainder. This is better than calculating the two of them separately, because that would require the operation to be performed twice.

`hugeint.ishugeint(hugeint):boolean`\
Returns whether the given value is a hugeint or not.

`hugeint.sqrt(n):hugeint`\
Calculates the square root of the input (rounded down), and throws an error for strictly negative numbers.

`hugeint.tonumber(hugeint):number`\
Converts a hugeint into a number. Sadly, a `__tonumber` metamethod doesn't exist, so this is the alternative.

`hugeint.meta`\
The metatable used for hugeints. This metatable defines the following operations:
- `+`, `-`, `*`, `/`, `%`, `^`, unary `-`: these do what they are expected to. A second argument which is convertible to a hugeint will be converted to a hugeint. The result is always a hugeint. If the second argument is not convertible to a hugeint, an error is thrown.
- `..`: this applies `tostring()` first.
- `#`: throws an error with a message `attempt to get length of a hugeint value`.
- `==`, `~=`: compares the hugeints numerically, but doesn't convert numbers or strings to hugeints.
- `<`, `<=`, `>`, `>=`: first converts, then compares.
- `[]` (index): refers to the `hugeint` library table.
- `()` (call): throws an error with a message `attempt to call a hugeint value`.
- `ipairs()`, `pairs()`: throws an error.
- `tostring()`: converts a hugeint to a string, like it is expected.

The following apply to Lua 5.3 only (but their metamethods can be used directly in Lua 5.2):
- `//`: same as `/`, as the result is already an integer.

#### Known bugs
- The multiplication routine returns a wrong answer. This causes the power routine to do the same.
- `hugeint.sqrt()` returns a wrong answer.

#### Planned features
`hugeint.format(hugeint,format):string`\
Formats a hugeint similarily to `string.format()`, but the format string only allows one formatting specifier, which also has to be one of `d`, `o`, `x`, and `X`. The formatting specifier cannot be preceded by a `%` and no other characters can occur in the string. Flags are still supported, except for the `*` flag. Also, note that the order of arguments is the other way around in this function. This is so that an object-oriented syntax can be used (`number:format("02X")` instead of `hugeint.format(number,"02X")`).

These operators (only exist in Lua 5.3, but their metamethods can still be used directly in Lua 5.2):\
- `&`, `|`, `~`, `~` (unary), `<<`, `>>`: behave as the basic arithmetic operations. Important to note is that these operators will handle negative numbers as two's complement, which means that negative numbers will (virtually) be extended infinitely to the left, with all `1`s. These `1`s are of course not factually stored.

### `unicode`

#### Methods
Please look at the `string` section of the [Lua Reference Manual](https://www.lua.org/manual/5.2/manual.html#6.4). The following functions there are also available in `unicode`, but it handles the strings as UTF-8. Indexes into the strings are also per character, not per byte:

`string.byte()`, `string.char()`, `string.find()`, `string.len()`, `string.lower()`, `string.match()`, `string.reverse()`, `string.sub()`, `string.upper()`

In most of these, only indexes into the string matter; these are converted from UTF-8 to bytes before the call to the original string function and back after. Big exceptions are `string.lower()` and `string.upper()`, which actually need to know a little about Unicode to work. As long as fghlib is maintained, these two will be updated to handle any new characters.

The following functions were also added:

`unicode.strToUTF(s,i):number`\
Converts a byte-oriented index to a character-oriented index. `s` is the string in which to look for the character, `i` is the byte-oriented index. `i` can point to any byte of the character.

`unicode.utfToStr(s,i):number`\
Converts a character-oriented index to a byte-oriented index. This is the reverse of `unicode.strToUTF()`. It returns the index of the first byte of the character.

All functions' behaviour is undefined if the string is not validly UTF-8 encoded.

#### Known bugs
- `unicode.lower()` and `unicode.upper()` don't work. This bug is still being researched. The data they use (Unicode character blocks) are also incomplete.

#### Planned features
`unicode.conv(s,mode):string`\
Converts `s`, a string which is encoded in the mode `mode`, into the currently set mode by `unicode.mode()`.

`unicode.mode(mode):number`\
Allows change between UTF-8, UTF-16BE, UTF-16LE, UTF-32BE, and UTF-32LE. All other functions follow this. The argument is one of the numbers `8`, `16`, and `32`. Use a negative number for BE instead of LE. `-8` has the same behaviour as `8`. The returned value is what the mode was before this function was called. The default for `mode` is the current mode, so call `unicode.mode()` without arguments to get the current mode.

`unicode.valid(s):boolean`\
Returns `true` if `s` is validly encoded in the currently set UTF mode. Returns `false` if it's not.

`unicode.wlen(s):number`\
This returns a number, the number of character spaces the string would take up on the screen. For example, `"ツ"` returns `2`, while `"a"` returns `1`.
