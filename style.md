# fghsgh's code style

Please respect these when contributing. You can of course use your own style for your own code.

- Intentation happens with two spaces.
- If eight spaces at the beginning of the line occur, these may be replaced by a tab.
- Strings are always written with either `"` or `[=...=[` and `]=...=]`. For the `[=...=[`, the smallest possible amount of equal signs must be used, preferably 0.
- There are never two statements on the same line.
- Unrelated pieces of code should each be in their own `do`...`end`, but there must be at least an empty line between them.
- There are no whitespace characters at the end of a line. This includes empty lines.
- Variables must be declared as locally as possible, unless it has a major effect on performance.
- The string library must not be directly used; instead, use the object-oriented style (`s:byte()` instead of `string.byte(s)`). This is a little faster.
- Libraries have the following structure:
  - Two line comments:
    - The first line gives the name of the library and the link to this repository.
    - The second line gives credit to all writers of this library and mentions the GPL.
  - A line break.
  - Library `require()`s, in alphabetical order.
  - A line break.
  - The declaration of the library's table.
  - A line break.
  - Any global variables to the entire library (these are not actually global, but local in the scope of the file).
  - A line break.
  - All local functions used by the library. Each function is separated with a line break and has a comment above it describing its function.
  - A line break.
  - All library's functions, separated by line breaks.
  - A line break.
  - A return statement which returns the library's table.
- Functions must be called by using the `()` operator, the syntactic sugar `{}` and `""` is not allowed.
- The `()` operator for function calls must be directly following the function's name, without a space in between.
- Binary operators which do not consist of brackets must be surrounded by spaces.
  - The exception is the `=` in a numeric `for` statement, which does not have any spaces around it.
- Binary operators which do constist of brackets, must have spaces on the outside, but none on the inside.
  - The exception is the function call operator and the index operator, `()` and `[]` respectively. These only have a space after them.
- Unary operators have a space before them, but not after them.
- Numbers must be written in decimal, unless they have a binary meaning, or if they are commonly written in hexadecimal in this use, in which case they must be written in hexadecimal.
  - Examples are character codes and bit masks.
  - `A`-`F` are written in lowercase.
- If a function is defined with a name, the name must come between the function and the arguments of the function, if the syntax allows it (for example, this is impossible inside a table).
- If a function doesn't have a name, the arguments of the function must come directly after the `function` keyword, with no space in between.
- If a function's name consists of more than two words, every word from the second onward must be capitalized.
- If a function's name consists of exactly two words, there is no capitalization.
- No identifier must begin with a capital letter. Not even if it would be a class in a true object-oriented language.
- When defining a table with non-numeric fields, each field must come on a new line. The comma separating two fields must come at the end of the previous line. A comma should not be written after the last field.
- No spaces surround commas.
- When defining a non-integer number, with no integer part, there should not be a `0` before the `.`.
- Choosing variable names: a variable should either:
  - Index variables and variables used in for statements are single-letter variables, starting from `i`, alphabetically going on to `j`, `k`, `l`, and so on for nested loops.
  - Variable names can be shortened, as long as their unshortened meaning is either evident or added in a comment.
  - In general, a variable's name follows the same rule as for a function (functions are variables, after all).
  - The following one-letter names are allowed:
    - Index variables (`i`, `j`, `k`...)
    - `b` for byte
    - `k` for key (index in a table which is not a number)
    - `n` for number
    - `s` for string
    - `t` for table
    - `v` for value
    - In other cases: if the variable is used a lot, and an explanation is added in a comment.
- My name is written `fghsgh`, not `Fghsgh`, `FGHSGH`, or any other capitalization.
