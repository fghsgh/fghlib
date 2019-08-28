# lua-libs
These are some pure Lua libraries, for those of you who don't want to install C libraries and/or don't have root access. Please note that using these can be a lot slower than using C implementations.

All of these are for Lua 5.2, but probably also work on Lua 5.3.

All of these work on most Linux installations. On Windows, I can only guarantee that the ones with (no dependencies) will work.

These libraries are distributed under the GPL.

- `data`: deflate/inflate, CRC, SHA... (no dependencies)
- `fs`: more filesystem functionality, like reading directories, getting/setting permissions, modified dates, creating directories, removing files... (needs the standard UNIX programs and `io.popen()`)
- `http`: HTTP GET/POST using CURL (needs CURL and `io.popen()`)
- `hugeint`: infinite-width integers, implemented using tables and metamethods (no dependencies)
- `parallel`: running multiple Lua functions simultaneously, through the use of the coroutine and debug libraries, this is not real multithreading, though (no dependencies)
- `regex`: regular expressions (standard, extended, and Perl) (no dependencies)
- `shell`: running shell commands with escaped arguments and POSIX-compliant getopt (no dependencies)
- `term`: ncurses-like library (needs the `stty` program, `termcap`, `unicode`, and `io.popen()`)
- `termcap`: termcap reader, this can do basic stuff like setting the text color or cursor position (needs the termcap database)
- `unicode`: utf-8 port of the string library, using the string library (no dependencies)
- `xml`: XML parsing (no dependencies)

The full list of libraries with no dependencies: `data`, `hugeint`, `regex`, `shell`, `unicode`, `xml`.

These example programs are also included:

- `bigcalc`: big integer calculator (uses `hugeint`)
- `edit`: a simple text editor (uses `shell`, `term`)
- `fetch`: send a GET request and write the output to stdout (uses `http`)
- `kissanime-dl`: download entire anime seasons at once from KissAnime (uses `http`, `regex`, `shell`, `xml`)
- `lua`: a Lua interpreter with syntax highlighting and tab autocompletion (uses `regex`, `shell`, `term`)
- `search`: search the content of files for a regex (uses `regex`, `shell`)


## `unicode`

Please look at the `string` section of the [Lua Reference Manual](https://www.lua.org/manual/5.2/manual.html#6.4). All functions there are also available in `unicode`, but it handles the strings as UTF-8. Indexes into the strings are also per character, not per byte. The following function is added:

`unicode.wlen(s):number`\
This returns a number, the number of character spaces the string would take up on the screen. For example, `"ツ"` returns `2`, while `"a"` returns `1`.
