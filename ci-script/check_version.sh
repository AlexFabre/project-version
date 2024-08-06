#!/bin/sh

# Define the file paths
FILE1="$1" # The script.sh
FILE2="$2" # The header.h

# Check if FILE1 is provided
if [ -z "$FILE1" ]; then
    echo "Usage: $0 <path_to_firmware_script.sh> <path_to_generated_version.h>"
    exit 1
fi

# Check if FILE2 is provided
if [ -z "$FILE2" ]; then
    echo "Usage: $0 <path_to_firmware_script.sh> <path_to_generated_version.h>"
    exit 1
fi

# Function to extract values from c-versionner.sh script
extract_from_script() {
    var_name=$1
    grep "^$var_name" "$FILE1" | cut -d '=' -f 2 | tr -d ' \t'
}

# Function to extract values from generated header file
extract_from_header() {
    var_name=$1
    grep "^#define[ \t]\+$var_name" "$FILE2" | awk '{print $3}'
}

# Extract values from c-versionner.sh script
VERSION_MAJOR_FILE1=$(extract_from_script "C_VERSIONNER_MAJOR")
VERSION_MINOR_FILE1=$(extract_from_script "C_VERSIONNER_MINOR")
VERSION_PATCH_FILE1=$(extract_from_script "C_VERSIONNER_PATCH")

# Extract values from generated header file
VERSION_MAJOR_FILE2=$(extract_from_header "VERSION_MAJOR")
VERSION_MINOR_FILE2=$(extract_from_header "VERSION_MINOR")
VERSION_PATCH_FILE2=$(extract_from_header "VERSION_PATCH")

# Initialize the status flag
status=0

# Compare the values
compare_versions() {
    var_name=$1
    value1=$2
    value2=$3

    if [ "$value1" != "$value2" ]; then
        echo "$var_name values are different:"
        echo "$FILE1: $var_name=$value1"
        echo "$FILE2: $var_name=$value2"
        status=1
    fi
}

# Perform comparisons
compare_versions "MAJOR" "$VERSION_MAJOR_FILE1" "$VERSION_MAJOR_FILE2"
compare_versions "MINOR" "$VERSION_MINOR_FILE1" "$VERSION_MINOR_FILE2"
compare_versions "BUILD" "$VERSION_PATCH_FILE1" "$VERSION_PATCH_FILE2"

# Return the status
exit $status
