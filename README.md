# c-versionner

A little POSIX script to generate version informations for your C project

## Code quality

~~~txt
ShellCheck - shell script analysis tool
version: 0.9.0
license: GNU General Public License, version 3
website: https://www.shellcheck.net
~~~

## TODO List

* Script call checks: The script uses positional arguments to determine the file path and tag prefix. It would be better to use named arguments or flags for clarity and ease of use.
* Path handling in `file_path_checker` function: The function currently assumes that the provided path always ends with a filename. If the input path doesn't have a filename or extension, it defaults to `version.h`. This could lead to incorrect behavior in some cases. Consider validating the input path and handling errors more explicitly.
* Git commands: The script uses `git describe` and `git rev-parse` commands to extract information from the Git repository. These commands rely on the availability of Git and may fail if Git is not installed or if the script is run outside of a Git repository. Error handling should be added to handle such cases.
