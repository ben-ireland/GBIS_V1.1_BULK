#!/bin/bash
# Script to copy and update names of files in given directory containing a given SEARCH_STRING
# Replaces OLD_PATTERN with NEW_PATTERN in the copied files

# Directory to search
DIR="/scratch/Ben/GBIS_BULK/Manual_Inputs/AOI/"

# String to search for inside files
SEARCH_STRING="Suswa_S1_EP1_Dsc"

# Filename pattern to replace
OLD_PATTERN="Dsc"

# Replacement pattern
NEW_PATTERN="Dsc_V2"

find "$DIR" -type f -name "*${SEARCH_STRING}*" | while IFS= read -r file; do
    dir=$(dirname "$file")
    filename=$(basename "$file")

    # Replace "OLD_PATTERN" with "NEW_PATTERN" in the filename
    new_filename="${filename/$OLD_PATTERN/$NEW_PATTERN}"

    # Copy only if the filename changes
    if [[ "$filename" != "$new_filename" ]]; then
        cp -- "$file" "$dir/$new_filename"
        echo "Copied: $filename -> $new_filename"
    fi
done