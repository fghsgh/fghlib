# fghlib
This is a collection of pure Lua libraries, for those of you who don't want to install C libraries and/or don't have root access. Please note that using these can be a lot slower than using C implementations.

All of these are written for Lua 5.2, but also work on Lua 5.3 unless stated otherwise.

All of these work on most Linux installations. On Windows, I can only guarantee that the ones with `(no dependencies)` will work.

These libraries are distributed under the GPL. Please read [my code style](style.md) before contributing.

## Currently implemented
- `unicode`: utf-8 port of the string library, using the string library (no dependencies) [(documentation)](#unicode)

## Planned
- `data`: deflate/inflate, CRC, SHA... (no dependencies)
- `fs`: more filesystem functionality, like reading directories, getting/setting permissions, modified dates, creating directories, removing files... (needs the standard UNIX programs and `io.popen()`)
- `http`: HTTP GET/POST using CURL (needs CURL and `io.popen()`)
- `hugeint`: infinite-width integers, implemented using binary strings and metatables (no dependencies)
- `parallel`: running multiple Lua functions simultaneously, through the use of the coroutine and debug libraries, this is not real multithreading, though (no dependencies)
- `regex`: regular expressions (standard, extended, and Perl) (no dependencies)
- `shell`: running shell commands with escaped arguments and POSIX-compliant getopt (no dependencies)
- `term`: ncurses-like library (needs the `stty` program, `termcap`, `unicode`, and `io.popen()`)
- `termcap`: termcap reader, this can do basic stuff like setting the text color or cursor position (needs the termcap database)
- `xml`: XML parsing (no dependencies)

The full list of libraries with no dependencies: `data`, `hugeint`, `regex`, `shell`, `unicode`, `xml`.

## Planned example programs
- `bigcalc`: big integer calculator (uses `hugeint`)
- `edit`: a simple text editor (uses `shell`, `term`)
- `fetch`: send a GET request and write the output to stdout (uses `http`)
- `kissanime-dl`: download entire anime seasons at once from KissAnime (uses `http`, `regex`, `shell`, `xml`)
- `lua`: a Lua interpreter with syntax highlighting and tab autocompletion (uses `regex`, `shell`, `term`, `unicode`)
- `search`: search the content of files for a regex (uses `regex`, `shell`)


## Library documentation
This is not on a wiki because this repository was originally private and I didn't have premium.
### `unicode`

#### Methods
Please look at the `string` section of the [Lua Reference Manual](https://www.lua.org/manual/5.2/manual.html#6.4). The following functions there are also available in `unicode`, but it handles the strings as UTF-8. Indexes into the strings are also per character, not per byte:

`string.byte()`, `string.char()`, `string.find()`, `string.len()`, `string.lower()`, `string.match()`, `string.reverse()`, `string.sub()`, `string.upper()`

In most of these, only indexes into the string matter; these are converted from UTF-8 to bytes before the call to the original string function and back after. Big exceptions are `string.lower()` and `string.upper()`, which actually need to know a little about Unicode to work. As long as fghlib is maintained, these will be updated to handle new characters.

The following functions were also added:

`unicode.strToUTF(s,i):number`\
Converts a byte-oriented index to a character-oriented index. `s` is the string in which to look for the character, `i` is the byte-oriented index. `i` can point to any byte of the character.

`unicode.utfToStr(s,i):number`\
Converts a character-oriented index to a byte-oriented index. This is the reverse of `unicode.strToUTF()`. It returns the index of the first byte of the character.

All functions are undefined if the string is not validly UTF-8 encoded.

#### Known bugs
- `unicode.lower()` and `unicode.upper()` don't work. This bug is still being researched. The data they use (Unicode character blocks) are also incomplete.

#### Planned features
`unicode.mode(mode):number`\
Allows change between UTF-8, UTF-16BE, UTF-16LE, UTF-32BE, and UTF-32LE. All other functions follow this. The argument is one of the numbers `8`, `16`, and `32`. Use a negative number for BE instead of LE. `-8` has the same behaviour as `8`. The returned value is what the mode was before this function was called. The default for `mode` is the current mode, so call `unicode.mode()` without arguments to get the current mode.

`unicode.wlen(s):number`\
This returns a number, the number of character spaces the string would take up on the screen. For example, `"ツ"` returns `2`, while `"a"` returns `1`.
