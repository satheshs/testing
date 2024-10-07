#!/bin/bash

# Target branch to compare with
TARGET_BRANCH="main"

# Include and exclude lists
INCLUDE_LIST=("*.py" "*.js" "config.yml")
EXCLUDE_LIST=("*.log" "*.tmp" "*.md")

# String for the expected strings
AUTO_GENERATED_STRING="Code generated"
COPYRIGHT_STRING="Copyright"

# Expected copyright years (array)
EXPECTED_YEARS=("2023" "2024")

# Step 1: Get the list of changed files from git diff
CHANGED_FILES=$(git diff --name-only $TARGET_BRANCH)

# Step 2: Function to check if a file matches a pattern
matches_pattern() {
    local file=$1
    shift
    local patterns=("$@")
    for pattern in "${patterns[@]}"; do
        if [[ $file == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Step 3: Check if the file contains "// Code generated"
contains_generated_code() {
    local file=$1
    if grep -q $AUTO_GENERATED_STRING "$file"; then
        return 0
    fi
    return 1
}

# Step 4: Check if the file contains a copyright
contains_copyright() {
    local file=$1
    if grep -q $COPYRIGHT_STRING "$file"; then
        return 0
    fi
    return 1
}

# Step 5: Check if the copyright year is in the expected years
check_copyright_year() {
    local file=$1
    for year in "${EXPECTED_YEARS[@]}"; do
        if grep -q "Copyright.*$year" "$file"; then
            return 0
        fi
    done
    return 1
}

# Step 6: Process each changed file
for file in $CHANGED_FILES; do
    # Step 7: Check against the exclude list
    if matches_pattern "$file" "${EXCLUDE_LIST[@]}"; then
        echo "Skipping excluded file: $file"
        continue
    fi

    # Step 8: Check against the include list
    if matches_pattern "$file" "${INCLUDE_LIST[@]}"; then
        echo "Processing included file: $file"
    else
        echo "File $file is neither included nor excluded"
    fi

    # Step 9: Check if file contains "// Code generated"
    if contains_generated_code "$file"; then
        echo "Skipping code-generated file: $file"
        continue
    fi

    # Step 10: Check for existing copyright
    if contains_copyright "$file"; then
        echo "File $file contains copyright information."
    else
        echo "File $file is missing copyright information. Failing..."
        exit 1
    fi

    # Step 11: Check for correct copyright year
    if check_copyright_year "$file"; then
        echo "File $file has a valid copyright year."
    else
        echo "File $file has an incorrect or missing copyright year. Failing..."
        exit 1
    fi
done
