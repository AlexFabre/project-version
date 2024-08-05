#!/bin/sh
# ==========================================
#   c-versionner - A little POSIX shell script to generate
#                  version information for your C project
#   Copyright (C) 2024 Alex Fabre
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

# ==========================================
# Usage with standard tag names vXX.YY.ZZ
#   $> c-versionner.sh -o dir/subdir/file_version.h
#
# Usage with custom tag names fw-XX.YY.ZZ
#   $> c-versionner.sh -o dir/subdir/file_version.h -f fw-
# 
# ==========================================

# Script self version information
C_VERSIONNER_MAJOR=0
C_VERSIONNER_MINOR=3
C_VERSIONNER_FIX=2

# Print variables
C_VERSIONNER="c-versionner.sh"
C_VERSIONNER_REV="$C_VERSIONNER_MAJOR.$C_VERSIONNER_MINOR.$C_VERSIONNER_FIX"
C_VERSIONNER_INTRO_L1="A little POSIX shell script to generate"
C_VERSIONNER_INTRO_L2="version information for your C project"

# ==========================================
# Default settings
# ==========================================

# If the path provided with option -o does end on a directory 
# with a trailing '/' (ex. -o dir/subdir/ ), then the script
# will create the file version.h in that directory
DEFAULT_FILE_NAME="version.h"

# Extension to look for when checking that the path 
# given with option -o leads to a header file
EXTENSION=".h"

# By default the script will look for tags in the format
# v1.0.4
# Option -f allow for custom tag prefix
# ex. "-f fv-" if your tags are like this "fw-1.0.4" 
TAG_PREFIX="v"

# By default the script runs and prints only:
# On success:
# ==> "./version.h" updated: v0.3.2 (sha: e03685b)
# On failure:
# ==> No previous tag found
# ==> "./version.h" updated: v0.0.0 (sha: e03685b)
# With option -l the logs of the script are printed
# out during execution
LOG_VERBOSITY=0

# Default file path output
OUTPUT_FILE_PATH=$DEFAULT_FILE_NAME

# ==========================================
# Script call checks
# ==========================================

# The user has to provide the path for the
# dest file when calling the script
usage() {
    echo "==> $C_VERSIONNER $C_VERSIONNER_REV"
    echo "$C_VERSIONNER_INTRO_L1"
    echo "$C_VERSIONNER_INTRO_L2"
    echo "Usage:"
    echo "$C_VERSIONNER [options]"
    echo "-o <output file path>"
    echo "-f <tag format> (default 'v')"
    echo "-h <help>"
    echo "-v <script version>"
    echo "-l <script logs> (default none)"
}

# Check the call of the script
while getopts ":o:f:hvl" opt; do
    case "${opt}" in
        o)
            OUTPUT_FILE_PATH=${OPTARG}
            ;;
        f)
            TAG_PREFIX=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        v)
            echo "$C_VERSIONNER_REV"
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

# Checks that the path finishes with a valid filename
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
    filename="$DEFAULT_FILE_NAME"
    fi

    # Appends the extension if missing
    filename="${filename%"$EXTENSION"}$EXTENSION"

    # Return the updated path
    echo "$(dirname "$1")/$filename"
}

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

git_version=$(git --version)
log "$git_version"

# Version file path
FILE_PATH=$(file_path_checker "$OUTPUT_FILE_PATH")

log "output file:" "$FILE_PATH"

log "tag prefix:" "$TAG_PREFIX"

tag_list=$(git tag -l "$TAG_PREFIX""[0-9]*.[0-9]*.[0-9]*")
log "tag list:" "$tag_list"

# Git describe command
GIT_DESCRIBE=$(git describe --tags --long --match "${TAG_PREFIX}[0-9]*.[0-9]*.[0-9]*" 2> /dev/null)
log "git describe output:" "$GIT_DESCRIBE"

# Check the length of the git describe result
# Because when no previous tags are found, describe returns nothing
if [ -z "$GIT_DESCRIBE" ]; then
    echo "==> No previous tag found"
    FW_MAJOR="0"
    FW_MINOR="0"
    FW_FIX="0"
    NB_COMMIT_SINCE_LAST_TAG="0"
else
    # Parse the result
    # ex: if GIT_DESCRIBE is "v1.0.4-14-g2414721"
    #     then  FW_MAJOR = 1
    #           FW_MINOR = 0
    #           FW_FIX = 4
    #           NB_COMMIT_SINCE_LAST_TAG = 14

    # Extract the version parts using substring manipulation

    # Remove the leading tag prefix
    GIT_DESCRIBE="${GIT_DESCRIBE#"$TAG_PREFIX"}"

    # Extract the version parts using substring manipulation
    FW_MAJOR="${GIT_DESCRIBE%%.*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_MAJOR".}"

    FW_MINOR="${GIT_DESCRIBE%%.*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_MINOR".}"

    FW_FIX="${GIT_DESCRIBE%%-*}"
    GIT_DESCRIBE="${GIT_DESCRIBE#"$FW_FIX"-}"

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
BASENAME="$(basename "$FILE_PATH")"

# Change filename chars to UPPER and non-alphanum to UNDERSCORES...
BUILD_LOCK=$(echo "${BASENAME}" | awk 'BEGIN { getline; print toupper($0) }' | sed 's/[^[:alnum:]\r\t]/_/g')

MACRO_PREFIX="${BUILD_LOCK#_}"
MACRO_PREFIX="${MACRO_PREFIX%%_*}"

# Modify the tmp version file
{   echo "/**";
    echo " * @file $BASENAME";
    echo " * @brief version info of project build";
    echo " *";
    echo " * Generated with $C_VERSIONNER $C_VERSIONNER_REV";
    echo " * $C_VERSIONNER_INTRO_L1";
    echo " * $C_VERSIONNER_INTRO_L2";
    echo " */";
    echo "#ifndef _${BUILD_LOCK}_";
    echo "#define _${BUILD_LOCK}_";
    echo "";
    echo "/* Project version */";
    echo "#define ""$MACRO_PREFIX""_MAJOR                     $FW_MAJOR";
    echo "#define ""$MACRO_PREFIX""_MINOR                     $FW_MINOR";
    echo "#define ""$MACRO_PREFIX""_FIX                       $FW_FIX";
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
    echo "#endif /* _${BUILD_LOCK}_ */";
} > "${FILE_PATH}_tmp.h"

if cmp -s "${FILE_PATH}" "${FILE_PATH}_tmp.h"
then
    # New file and previous one are identical. No need to rewrite it
    rm "${FILE_PATH}_tmp.h"
    echo "==> \"$FILE_PATH\" unchanged: $TAG_PREFIX$FW_MAJOR.$FW_MINOR.$FW_FIX (sha: $COMMIT_SHA)"
    exit 0 # exit with the success code
else
    mv "${FILE_PATH}_tmp.h" "${FILE_PATH}"
    echo "==> \"$FILE_PATH\" updated: $TAG_PREFIX$FW_MAJOR.$FW_MINOR.$FW_FIX (sha: $COMMIT_SHA)"
    exit 0 # exit with the success code
fi