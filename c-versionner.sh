#!/bin/sh
# ==========================================
#   c-versionner - A little POSIX shell script to generate
#                  version informations for your C project
#   Copyright (C) 2023 Alex Fabre
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

# ==========================================
# Usage with standard tag names vXX.YY.ZZ
#   $> c-versionner.sh dir/subdir/file_version.h
#
# Usage with custom tag names fw-XX.YY.ZZ
#   $> c-versionner.sh dir/subdir/file_version.h fw-
# 
# ==========================================

C_VERSIONNER_MAJOR=0
C_VERSIONNER_MINOR=2
C_VERSIONNER_FIX=0

C_VERSIONNER_REV="$C_VERSIONNER_MAJOR.$C_VERSIONNER_MINOR.$C_VERSIONNER_FIX"

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

# Default file path output
OUTPUT_FILE_PATH=$DEFAULT_FILE_NAME

# ==========================================
# Script call checks
# ==========================================

# The user has to provide the path for the
# dest file when calling the script
usage() {
    echo "==> c-versionner $C_VERSIONNER_REV"
    echo "A little POSIX shell script to generate"
    echo "version informations for your C project"
    echo "Usage:"
    echo "$0 [options]"
    echo "-o <output file path>"
    echo "-f <tag format>"
    echo "-h <help>"
    echo "-v <script version>"
}

# Check the call of the script
while getopts ":o:f:hv" opt; do
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
#           Ouput "src/subdir/version.h"
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

# ==========================================
# Script
# ==========================================

# Version file path
FILE_PATH=$(file_path_checker "$OUTPUT_FILE_PATH")

# Git describe command
GIT_DESCRIBE=$(git describe 2> /dev/null)

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

# Modify the tmp version file
{   echo "/*";
    echo " * File: $BASENAME";
    echo " * Generated with $(basename "$0") rev $C_VERSIONNER_REV";
    echo " */";
    echo "#ifndef _${BUILD_LOCK}_";
    echo "#define _${BUILD_LOCK}_";
    echo "";
    echo "/* Firmware version */";
    echo "#define FIRMWARE_VERSION_MAJOR    $FW_MAJOR";
    echo "#define FIRMWARE_VERSION_MINOR    $FW_MINOR";
    echo "#define FIRMWARE_VERSION_FIX      $FW_FIX";
    echo ""
    echo "#define BRANCH_NAME               \"$BRANCH_NAME\"";
    echo "#define NB_COMMITS_SINCE_LAST_TAG $NB_COMMIT_SINCE_LAST_TAG";
    echo "#define COMMIT_SHORT_SHA          \"$COMMIT_SHA\"";
    echo ""
    echo "/* Build date time (UTC) */";
    echo "#define BUILD_DAY          $DAY";
    echo "#define BUILD_MONTH        $MONTH";
    echo "#define BUILD_YEAR         $YEAR";
    echo "#define BUILD_HOUR         $HOUR";
    echo "";
    echo "#endif /* _${BUILD_LOCK}_ */";
} > "${FILE_PATH}_tmp.h"

if cmp -s "${FILE_PATH}" "${FILE_PATH}_tmp.h"
then
    # New file and previous one are identical. No need to rewrite it
    rm "${FILE_PATH}_tmp.h"
    echo "==> \"$FILE_PATH\" unchanged"
    exit 0 # exit with the success code
else
    mv "${FILE_PATH}_tmp.h" "${FILE_PATH}"
    echo "==> \"$FILE_PATH\" updated"
    exit 0 # exit with the success code
fi