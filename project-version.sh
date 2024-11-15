#!/bin/sh
# ==========================================
#   project-version - A little POSIX shell script to generate
#           version information for your C project
#   Copyright (C) 2024 Alex Fabre
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

# ==========================================
# Usage with standard tag names vXX.YY.ZZ
#   $> project-version.sh -o dir/subdir/version.h
#
# Usage with custom tag names fw-XX.YY.ZZ
#   $> project-version.sh -o dir/subdir/file_version.h -t fw-
# 
# ==========================================

# Script self version information
PROJECT_VERSION_MAJOR=0
PROJECT_VERSION_MINOR=6
PROJECT_VERSION_PATCH=0

# Print variables
PROJECT_VERSION_SCRIPT_NAME="project-version.sh"
PROJECT_VERSION_VERSION="$PROJECT_VERSION_MAJOR.$PROJECT_VERSION_MINOR.$PROJECT_VERSION_PATCH"
PROJECT_VERSION_INTRO_L1="A little POSIX shell script to generate"
PROJECT_VERSION_INTRO_L2="version information for your C project."
PROJECT_VERSION_INTRO_L3="ref: https://github.com/AlexFabre/project-version"

# ==========================================
# Default settings
# ==========================================

# Option -t <...>
# By default the script will look for tags in the format
# v1.0.4
# Option -t allow for custom tag prefix
# ex. "-t fv-" if your tags are like this "fw-1.0.4" 
GIT_TAG_PREFIX="v"

# Option -l
# By default the script runs and prints only:
# On success:
# ==> "./version.h" updated: v0.3.2 (sha: e03685b)
# On failure:
# ==> No previous tag found
# ==> "./version.h" updated: v0.0.0 (sha: e03685b)
# With option -l the logs of the script are printed
# out during execution
LOG_VERBOSITY=0

# If the path provided with option -o does end on a directory 
# (with a trailing '/' (ex. -o dir/subdir/ )), then the script
# will create the file in that directory with the following name:
DEFAULT_OUTPUT_FILE_NAME="version"

# Option -o <...>
# Default file path output
OUTPUT_FILE_PATH=$DEFAULT_OUTPUT_FILE_NAME

# Option -f <...>
# By default the script will generate a header file (.h) with the
# various definitions.
OUTPUT_FORMAT="h"

# ==========================================
# Script call checks
# ==========================================

usage() {
    echo "==> $PROJECT_VERSION_SCRIPT_NAME $PROJECT_VERSION_VERSION"
    echo "$PROJECT_VERSION_INTRO_L1"
    echo "$PROJECT_VERSION_INTRO_L2"
    echo "$PROJECT_VERSION_INTRO_L3"
    echo "Usage:"
    echo "$PROJECT_VERSION_SCRIPT_NAME <options>"
    echo "    -f <output format>"
    echo "        -f h : (default) Generate a C header file (.h)."
    echo "        -f hpp : Generate a C++ header file (.hpp)."
    echo "        -f cmake : Generate a cmake variable file."
    echo "    -o <output file name>"
    echo "    -t <git tag format> (default 'v') (ex. 'v' will match tags 'v0.3.1' and 'v0.2.1-beta' but not tags '1.3.4' nor 'version3.2.3')"
    echo "    -h <help>"
    echo "    -v <script version>"
    echo "    -l <script logs> (default none)"
}

# Check the call of the script
while getopts ":f:o:t:hvl" opt; do
    case "${opt}" in
        f)
            OUTPUT_FORMAT=${OPTARG}
            ;;
        o)
            OUTPUT_FILE_PATH=${OPTARG}
            ;;
        t)
            GIT_TAG_PREFIX=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        v)
            echo "$PROJECT_VERSION_VERSION"
            exit 0
            ;;
        l)
            LOG_VERBOSITY=1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# ==========================================
# Functions
# ==========================================

# Reads a given 'output file name' and echoes it back, properly formatted.
# If the file is not given, the default name 'version' is used.
#   ex. valid path with file name
#       Input "src/subdir/version.h"
#       Output "src/subdir/version.h"
# Error handling
#   - Output the default filename when missing
#   ex. Input "src/subdir/"
#       Output "src/subdir/version.h"
#   - Appends the default extension if missing
#   ex: Input "src/subdir/version"
#           Output "src/subdir/version.h"
file_path_checker() {
    # Get the last part of the path after the last '/'
    filename="${1##*/}"

    # Default filename when missing
    if [ -z "$filename" ]; then
    filename="$DEFAULT_OUTPUT_FILE_NAME""$OUTPUT_FILE_EXTENSION"
    fi

    # Appends the extension if missing
    filename="${filename%"$OUTPUT_FILE_EXTENSION"}$OUTPUT_FILE_EXTENSION"

    # Return the updated path
    echo "$(dirname "$1")/$filename"
}

# Print a log message
# Requires option -l
log() {
    if [ "$LOG_VERBOSITY" = "1" ]
    then
        echo "log: $1 $2"
    fi
}

# ==========================================
# Script
# ==========================================

# Check if git is installed
if ! command -v git >/dev/null 2>&1
then
    echo "Error: git is not installed."
    exit 1
fi

# Print git version
git_version=$(git --version)
log "$git_version"

# Handle file format depending on project format
log "Output format: $OUTPUT_FORMAT"
if [ "$OUTPUT_FORMAT" = "h" ]; then
    OUTPUT_FILE_EXTENSION=".h"
fi

if [ "$OUTPUT_FORMAT" = "hpp" ]; then
    OUTPUT_FILE_EXTENSION=".hpp"
fi

if [ "$OUTPUT_FORMAT" = "cmake" ]; then
    OUTPUT_FILE_EXTENSION=""
fi

# Version file path
FORMATED_OUTPUT_FILE_PATH=$(file_path_checker "$OUTPUT_FILE_PATH")

log "output file:" "$FORMATED_OUTPUT_FILE_PATH"

log "tag prefix:" "$GIT_TAG_PREFIX"

tag_list=$(git tag -l "$GIT_TAG_PREFIX""[0-9]*.[0-9]*.[0-9]*")
log "tag list:" "$tag_list"

# Git describe command
GIT_DESCRIBE=$(git describe --tags --long --match "${GIT_TAG_PREFIX}[0-9]*.[0-9]*.[0-9]*" 2> /dev/null)
log "git describe output:" "$GIT_DESCRIBE"

# Check the length of the git describe result
# Because when no previous tags are found, describe returns nothing
if [ -z "$GIT_DESCRIBE" ]; then
    echo "==> No previous tag found"
    FW_MAJOR="0"
    FW_MINOR="0"
    FW_PATCH="0"
    NB_COMMIT_SINCE_LAST_TAG="0"
else
    # Parse the result
    # ex: if GIT_DESCRIBE is "v1.0.4-14-g2414721"
    #     then  FW_MAJOR = 1
    #           FW_MINOR = 0
    #           FW_PATCH = 4
    #           NB_COMMIT_SINCE_LAST_TAG = 14

    # Extract the version parts using substring manipulation

    # Remove the leading tag prefix
    GIT_DESCRIBE="${GIT_DESCRIBE#"$GIT_TAG_PREFIX"}"

    # Extract the version parts using substring manipulation
    FW_MAJOR="${GIT_DESCRIBE%%.*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_MAJOR".}"

    FW_MINOR="${GIT_DESCRIBE%%.*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_MINOR".}"

    FW_PATCH="${GIT_DESCRIBE%%-*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_PATCH"-}"

    # Extract the number of commits since last tag
    NB_COMMIT_SINCE_LAST_TAG="${GIT_DESCRIBE%%-*}"
fi

# Commit short SHA
COMMIT_SHA=$(git rev-parse --short HEAD)

# Get branch name
BRANCH_NAME=$(git branch --show-current)
# Check the length of the variable BRANCH_NAME
# When running in CI it returns nothing
if [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME="main"
fi

# Current date and hour
YEAR=$(date -u +"%-Y")
DAY=$(date -u +"%-d")
MONTH=$(date -u +"%-m")
HOUR=$(date -u +"%-H")

# Extract filename with extension...
OUTPUT_FILE_NAME="$(basename "$FORMATED_OUTPUT_FILE_PATH")"

# Generated for a cmake project
if [ "$OUTPUT_FORMAT" = "cmake" ]; then
    # Modify the tmp version file
    {   echo "# This file declares the firmware revision information";
        echo "#";
        echo "# Generated with $PROJECT_VERSION_SCRIPT_NAME $PROJECT_VERSION_VERSION";
        echo "# $PROJECT_VERSION_INTRO_L1";
        echo "# $PROJECT_VERSION_INTRO_L2";
        echo "# $PROJECT_VERSION_INTRO_L3";
        echo "#";
        echo "# Do not edit this file manually. Its content";
        echo "# is generated with project-version.sh script.";
        echo "";
        echo "VERSION_MAJOR = $FW_MAJOR";
        echo "VERSION_MINOR = $FW_MINOR";
        echo "PATCHLEVEL = $FW_PATCH";
        echo "VERSION_TWEAK = $NB_COMMIT_SINCE_LAST_TAG";
        echo "EXTRAVERSION = $BRANCH_NAME";
    } > "${FORMATED_OUTPUT_FILE_PATH}_tmp"
else
    # Change filename chars to UPPER and non-alphanum to UNDERSCORES...
    BUILD_LOCK=$(echo "${OUTPUT_FILE_NAME}" | awk 'BEGIN { getline; print toupper($0) }' | sed 's/[^[:alnum:]\r\t]/_/g')

    MACRO_PREFIX="${BUILD_LOCK#_}"
    MACRO_PREFIX="${MACRO_PREFIX%%_*}"

    # Modify the tmp version file
    {   echo "/**";
        echo " * @file $OUTPUT_FILE_NAME";
        echo " * @brief This file declares the firmware revision information";
        echo " *";
        echo " * Generated with $PROJECT_VERSION_SCRIPT_NAME $PROJECT_VERSION_VERSION";
        echo " * $PROJECT_VERSION_INTRO_L1";
        echo " * $PROJECT_VERSION_INTRO_L2";
        echo " * $PROJECT_VERSION_INTRO_L3";
        echo " *";
        echo " * Do not edit this file manually. Its content";
        echo " * is generated with project-version.sh script.";
        echo " */";
        echo "#ifndef ${BUILD_LOCK}__";
        echo "#define ${BUILD_LOCK}__";
        echo "";
        echo "/* Project version */";
        echo "#define ""$MACRO_PREFIX""_MAJOR                     $FW_MAJOR";
        echo "#define ""$MACRO_PREFIX""_MINOR                     $FW_MINOR";
        echo "#define ""$MACRO_PREFIX""_PATCH                     $FW_PATCH";
        echo ""
        echo "/* Git repo info */";
        echo "#define ""$MACRO_PREFIX""_BRANCH_NAME               \"$BRANCH_NAME\"";
        echo "#define ""$MACRO_PREFIX""_NB_COMMITS_SINCE_LAST_TAG $NB_COMMIT_SINCE_LAST_TAG";
        echo "#define ""$MACRO_PREFIX""_COMMIT_SHORT_SHA          \"$COMMIT_SHA\"";
        echo ""
        echo "/* Build date time (UTC) */";
        echo "#define ""$MACRO_PREFIX""_BUILD_DAY                 $DAY";
        echo "#define ""$MACRO_PREFIX""_BUILD_MONTH               $MONTH";
        echo "#define ""$MACRO_PREFIX""_BUILD_YEAR                $YEAR";
        echo "#define ""$MACRO_PREFIX""_BUILD_HOUR                $HOUR";
        echo "";
        echo "#endif /* ${BUILD_LOCK}__ */";
    } > "${FORMATED_OUTPUT_FILE_PATH}_tmp${OUTPUT_FILE_EXTENSION}"
fi

if cmp -s "${FORMATED_OUTPUT_FILE_PATH}" "${FORMATED_OUTPUT_FILE_PATH}_tmp${OUTPUT_FILE_EXTENSION}"
then
    # New file and previous one are identical. No need to rewrite it
    rm "${FORMATED_OUTPUT_FILE_PATH}_tmp${OUTPUT_FILE_EXTENSION}"
    echo "==> \"$FORMATED_OUTPUT_FILE_PATH\" unchanged: $GIT_TAG_PREFIX$FW_MAJOR.$FW_MINOR.$FW_PATCH (sha: $COMMIT_SHA)"
    exit 0 # exit with the success code
else
    mv "${FORMATED_OUTPUT_FILE_PATH}_tmp${OUTPUT_FILE_EXTENSION}" "${FORMATED_OUTPUT_FILE_PATH}"
    echo "==> \"$FORMATED_OUTPUT_FILE_PATH\" updated: $GIT_TAG_PREFIX$FW_MAJOR.$FW_MINOR.$FW_PATCH (sha: $COMMIT_SHA)"
    exit 0 # exit with the success code
fi