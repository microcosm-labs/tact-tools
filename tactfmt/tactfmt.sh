#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 file1 [file2 ...]"
    exit 1
fi

# Get the directory of the current script
script_dir=$(dirname "$0")

# Loop through each file provided as an argument
for file in "$@"; do
    # Create a temporary file for the first pass
    # tmpfile1=$(mktemp)
    # Create a temporary file for the second pass
    tmpfile2=$(mktemp)

    # First pass: Ensure there is an empty line at the end of the file
    # awk '{ print $0; } END { print ""; }' "$file" > "$tmpfile1"

    # Second pass: Remove duplicate empty lines
    awk -f "$script_dir/tactfmt.awk" "$file" > "$tmpfile2"

    # Check if the temporary file is not empty
    if [ -s "$tmpfile2" ]; then
        # Replace the original file with the formatted file
        mv "$tmpfile2" "$file"
    else
        # Remove the temporary file if it's empty
        rm "$tmpfile2"
    fi

    # Clean up the first temporary file
    # rm "$tmpfile1"
done
