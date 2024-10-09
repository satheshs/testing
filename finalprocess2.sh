#!/bin/bash

# Target branch to compare with
TARGET_BRANCH="main"

# Include and exclude lists

INCLUDE_LIST=("*.py" "*.sh" "*.js" "*.go" "*.groovy" "*.yml" "*.yaml" "*sql" "*.cpp" "*.hpp" "*.c" "*.h")
#("*.py" "*.js" "*.sh")  # Extensions of files you want to include
EXCLUDE_LIST=("*.log" "*.tmp" "*.md")  # Extensions of files to exclude

# Expected copyright years (array)
EXPECTED_YEAR=$(date +"%Y")

# List to track failed files and their respective messages
FAILED_FILES=()
FAILED_MESSAGES=()

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
    if grep -q "// Code generated" "$file"; then
        return 0
    fi
    return 1
}

# Step 4: Check if the file contains a copyright
contains_copyright() {
    local file=$1
    if grep -q "Copyright" "$file"; then
        return 0
    fi
    return 1
}

# Step 5: Check if any of the expected years are in the copyright
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

    # Step 8: Check against the include list
    if ! matches_pattern "$file" "${INCLUDE_LIST[@]}"; then
        continue
    fi

    # Step 9: Check if file contains "// Code generated"
    if contains_generated_code "$file"; then
        continue
    fi

    # Step 10: Check for existing copyright
    if ! contains_copyright "$file"; then
        FAILED_FILES+=("$file")
        FAILED_MESSAGES+=("File $file is missing copyright information.")
        continue
    fi

    # Step 11: Check for correct copyright year
    if ! check_copyright_year "$file"; then
        FAILED_FILES+=("$file")
        FAILED_MESSAGES+=("File $file has an incorrect or missing copyright year.")
    fi
done

# Step 12: If any files failed, list them and then provide detailed error messages
if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
    echo "The following files failed validation:"
    
    # List all the failed files first
    for failed_file in "${FAILED_FILES[@]}"; do
        echo "$failed_file"
    done

    echo ""

    # Provide detailed error messages
    echo "Detailed error messages:"
    for failed_message in "${FAILED_MESSAGES[@]}"; do
        echo "$failed_message"
    done
    
    exit 1
else
    echo "All files passed validation."
    exit 0
fi
