# c-versionner

A little POSIX script to generate version informations for your C project

## Usage

Copy the script in your git working repo and let the magic happen.

All available options can be listed with option `-h`

~~~sh
$ ./c-versionner.sh -h
==> c-versionner 0.3.2
A little POSIX shell script to generate
version informations for your C project
Usage:
./c-versionner.sh [options]
-o <output file path>
-f <tag format>
-h <help>
-v <script version>
~~~

### Example of generated header

~~~c
/**
 * @file version.h
 * @brief version info of project build
 * 
 * Generated with c-versionner.sh 0.3.2
 * A little POSIX shell script to generate
 * version informations for your C project
 */
#ifndef _VERSION_H_
#define _VERSION_H_

/* Project version */
#define PROJECT_VERSION_MAJOR     1
#define PROJECT_VERSION_MINOR     0
#define PROJECT_VERSION_FIX       4

/* Git repo info */
#define BRANCH_NAME               "main"
#define NB_COMMITS_SINCE_LAST_TAG 14
#define COMMIT_SHORT_SHA          "60ab8e4"

/* Build date time (UTC) */
#define BUILD_DAY                 16
#define BUILD_MONTH               10
#define BUILD_YEAR                2023
#define BUILD_HOUR                14

#endif /* _VERSION_H_ */
~~~

## Code quality

~~~txt
ShellCheck - shell script analysis tool
version: 0.10.0
license: GNU General Public License, version 3
website: https://www.shellcheck.net
~~~

## TODO List

* Path handling in `file_path_checker` function: The function currently assumes that the provided path always ends with a filename. If the input path doesn't have a filename or extension, it defaults to `version.h`. This could lead to incorrect behavior in some cases. Consider validating the input path and handling errors more explicitly.
* Git commands: The script uses `git describe` and `git rev-parse` commands to extract information from the Git repository. These commands rely on the availability of Git and may fail if Git is not installed or if the script is run outside of a Git repository. Error handling should be added to handle such cases.
