# c-versionner

A little POSIX script to generate version informations for your C project

## Usage

Copy the script in your git working repo and let the magic happen.

All available options can be listed with option `-h`

~~~sh
$ ./c-versionner.sh -h
==> c-versionner 1.0.0
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
/*
 * File: version.h
 * Generated with c-versionner.sh rev 1.0.0
 */
#ifndef _VERSION_H_
#define _VERSION_H_

/* Firmware version */
#define FIRMWARE_VERSION_MAJOR    1
#define FIRMWARE_VERSION_MINOR    0
#define FIRMWARE_VERSION_FIX      4

#define BRANCH_NAME               "main"
#define NB_COMMITS_SINCE_LAST_TAG 14
#define COMMIT_SHORT_SHA          "0be5335"

/* Build date time (UTC) */
#define BUILD_DAY          16
#define BUILD_MONTH        10
#define BUILD_YEAR         2023
#define BUILD_HOUR         13

#endif /* _VERSION_H_ */
~~~

## Code quality

~~~txt
ShellCheck - shell script analysis tool
version: 0.9.0
license: GNU General Public License, version 3
website: https://www.shellcheck.net
~~~

## TODO List

* Path handling in `file_path_checker` function: The function currently assumes that the provided path always ends with a filename. If the input path doesn't have a filename or extension, it defaults to `version.h`. This could lead to incorrect behavior in some cases. Consider validating the input path and handling errors more explicitly.
* Git commands: The script uses `git describe` and `git rev-parse` commands to extract information from the Git repository. These commands rely on the availability of Git and may fail if Git is not installed or if the script is run outside of a Git repository. Error handling should be added to handle such cases.
