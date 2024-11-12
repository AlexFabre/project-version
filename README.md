# rever

A little POSIX shell script that generates a C header containing the version information (Major Minor etc...) of a Git based repository.

The script simply parses the `git describe` command to extract the firmware information, and create the corresponding defines.

## Compatibility

### Genuine C/C++ project

The script will generate a C header file.

```sh
./rever.sh -o project/include/version.h
```

### Zephyr project

The script will generate the cmake version file.

```sh
./rever.sh -f zephyr -o cmake-project/VERSION
```

## Requirements

- Restricted to git based repository.
- Git must be available from the PATH. (On windows, run the script with git bash).

## Usage

Clone the repo or simply copy the `rever.sh` script into your repository and let the magic happen.

All available options can be listed with option `-h`

~~~sh
$ ./rever.sh -h
==> rever.sh 0.5.0
A little POSIX shell script to generate
version information for your C project.
ref: https://github.com/AlexFabre/rever
Usage:
rever.sh <options>
    -f <project format>
        -f zephyr: Generate a 'VERSION' file, specific to zephyr projects
        -f base: (default) Generate the basic rever format file
    -o <output file>
    -t <git tag format> (default 'v')
    -h <help>
    -v <script version>
    -l <script logs> (default none)
~~~

### Example of generated header for C/C++ project

~~~c
/**
 * @file version.h
 * @brief version information of project build
 *
 * Generated with rever.sh 0.5.0
 * A little POSIX shell script to generate
 * version information for your C project.
 * ref: https://github.com/AlexFabre/rever
 *
 * Do not edit this file manually. Its content
 * is generated with rever.sh script.
 */
#ifndef VERSION_H__
#define VERSION_H__

/* Project version */
#define VERSION_MAJOR                     0
#define VERSION_MINOR                     5
#define VERSION_PATCH                     0

/* Git repo info */
#define VERSION_BRANCH_NAME               "feat/add-zephyr-compatibility"
#define VERSION_NB_COMMITS_SINCE_LAST_TAG 6
#define VERSION_COMMIT_SHORT_SHA          "08df77b"

/* Build date time (UTC) */
#define VERSION_BUILD_DAY                 29
#define VERSION_BUILD_MONTH               10
#define VERSION_BUILD_YEAR                2024
#define VERSION_BUILD_HOUR                11

#endif /* VERSION_H__ */

~~~

### Example of generated header for Zephyr project

~~~txt

# This file declares the firmware revision information
# both for cmake and for mcuboot
#
# ref: https://docs.zephyrproject.org/latest/build/version/index.html
#
# Generated with rever.sh 0.5.0
# A little POSIX shell script to generate
# version information for your C project.
# ref: https://github.com/AlexFabre/rever
#
# Do not edit this file manually. Its content
# is generated with rever.sh script.

VERSION_MAJOR = 0
VERSION_MINOR = 5
PATCHLEVEL = 0
VERSION_TWEAK = 6
EXTRAVERSION = "feat/add-zephyr-compatibility08df77b"

~~~

## Code quality
- Shellcheck
- Codespell

## Improvements...

* Path handling in `file_path_checker` function: The function currently assumes that the provided path always ends with a filename. If the input path doesn't have a filename or extension, it defaults to `version.h`. This could lead to incorrect behavior in some cases. Consider validating the input path and handling errors more explicitly.
