#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install it first."
    exit 1
fi

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_json_file> <output_md_file>"
    exit 1
fi

# Check if output file is provided
if [ -z "$2" ]; then
    echo "Usage: $0 <input_json_file> <output_md_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist."
    exit 1
fi

# Create the output file with a header
echo "# RustHallows Approach Analysis" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Generated from JSON analysis on $(date '+%Y-%m-%d')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract and format the executive summary
echo "## Executive Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
jq -r '.output.executive_summary' "$INPUT_FILE" | fold -s -w 80 >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract and format the highest differentiation use cases
echo "## Highest Differentiation Use Cases" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| Use Case Category | Specific Examples | Core Problem Solved | Differentiation Level |" >> "$OUTPUT_FILE"
echo "|------------------|-------------------|---------------------|----------------------|" >> "$OUTPUT_FILE"

# Process each use case
jq -r '.output.highest_differentiation_use_cases[] | "| " + (.use_case_category // "-") + " | " + (.specific_examples // "-") + " | " + (.core_problem_solved // "-") + " | " + (.differentiation_level // "-") + " |"' "$INPUT_FILE" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract and format detailed analysis if it exists
if jq -e '.output.detailed_analysis' "$INPUT_FILE" > /dev/null 2>&1; then
    echo "## Detailed Analysis" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    jq -r '.output.detailed_analysis' "$INPUT_FILE" | fold -s -w 80 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Extract and format any additional sections that might exist
for key in $(jq -r '.output | keys[] | select(. != "executive_summary" and . != "highest_differentiation_use_cases" and . != "detailed_analysis")' "$INPUT_FILE"); do
    # Convert key from snake_case to Title Case for the heading
    SECTION_TITLE=$(echo "$key" | sed -e 's/_/ /g' -e 's/\b\(.\)/\u\1/g')
    
    echo "## $SECTION_TITLE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Check if the value is an array
    if jq -e ".output.$key | type == \"array\"" "$INPUT_FILE" > /dev/null; then
        # If it's an array of objects with specific fields, create a table
        if jq -e ".output.$key[0] | objects" "$INPUT_FILE" > /dev/null; then
            # Get the keys of the first object to use as table headers
            HEADERS=$(jq -r ".output.$key[0] | keys[]" "$INPUT_FILE")
            
            # Create table header row
            echo -n "| " >> "$OUTPUT_FILE"
            for header in $HEADERS; do
                HEADER_TITLE=$(echo "$header" | sed -e 's/_/ /g' -e 's/\b\(.\)/\u\1/g')
                echo -n "$HEADER_TITLE | " >> "$OUTPUT_FILE"
            done
            echo "" >> "$OUTPUT_FILE"
            
            # Create table separator row
            echo -n "| " >> "$OUTPUT_FILE"
            for header in $HEADERS; do
                echo -n "--- | " >> "$OUTPUT_FILE"
            done
            echo "" >> "$OUTPUT_FILE"
            
            # Create table data rows - handle different object structures
            jq -r ".output.$key[] | to_entries | map(.value) | \"| \" + (map(. // \"-\") | join(\" | \")) + \" |\"" "$INPUT_FILE" >> "$OUTPUT_FILE" 2>/dev/null || \
            echo "| - | - | - |" >> "$OUTPUT_FILE"
        else
            # If it's a simple array, list items with bullets
            jq -r ".output.$key[] | \"- \" + ." "$INPUT_FILE" >> "$OUTPUT_FILE"
        fi
    else
        # If it's an object, format each key-value pair
        if jq -e ".output.$key | type == \"object\"" "$INPUT_FILE" > /dev/null; then
            # Process each key in the object
            for field in $(jq -r ".output.$key | keys[]" "$INPUT_FILE"); do
                FIELD_TITLE=$(echo "$field" | sed -e 's/_/ /g' -e 's/\b\(.\)/\u\1/g')
                echo "### $FIELD_TITLE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
                jq -r ".output.$key.$field" "$INPUT_FILE" | fold -s -w 80 >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            done
        else
            # If it's a string, just output it with proper line wrapping
            jq -r ".output.$key" "$INPUT_FILE" | fold -s -w 80 >> "$OUTPUT_FILE"
        fi
    fi
    
    echo "" >> "$OUTPUT_FILE"
done

# Add input query if it exists
if jq -e '.input' "$INPUT_FILE" > /dev/null 2>&1; then
    echo "## Original Query" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    jq -r '.input' "$INPUT_FILE" | fold -s -w 80 >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

echo "Conversion complete. Markdown file created at: $OUTPUT_FILE"
