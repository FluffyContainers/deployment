
 https://stackoverflow.com/questions/53773118/refresh-first-n-lines-and-reset-cursor-to-the-end-of-current-line-with-escape-se


# Position the Cursor (Escape characters):

|         Description                    |      Sample         |
|----------------------------------------|---------------------|
| Put the cursor at line L and column C  | `\033[<L>;<C>H`     |
| Put the cursor at line L and column C  | `\033[<L>;<C>f`     |
| Move the cursor up N lines             | `\033[<N>A`         |
| Move the cursor down N lines           | `\033[<N>B`         |
| Move the cursor forward N columns      | `\033[<N>C`         |
| Move the cursor backward N columns     | `\033[<N>D`         |
| Clear the screen, move to (0,0)        | `\033[2J`           |
| Erase to end of line                   | `\033[K`            |
| Save cursor position                   | `\033[s`            |
| Restore cursor position                | `\033[u`            |




# Position the Cursor (tput):

|         Description                    |      Sample         |
|----------------------------------------|---------------------|
| Put  the cursor at line L and column C | `tput cup <L> <C>`  |
| Move the cursor up N lines             | `tput cuu <N>`      |
| Move the cursor down N lines           | `tput cud <N>`      |
| Move the cursor forward N columns      | `tput cuf <N>`      |
| Move the cursor backward N columns     | `tput cub <N>`      |
| Clear the screen, move to (0,0)        | `tput clear`        |
| Erase to end of line                   | `tput el`           |
| Save cursor position                   | `tput sc`           |
| Restore cursor position                | `tput rc`           |

