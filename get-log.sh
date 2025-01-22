#!/bin/bash
# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: az CLI is not installed. Please install az CLI before running this script."
    exit 1
fi

# Define variables
project_name="ade-sandbox-project"
environment_name="appconfig-tf"
operation_id="9d781997-1949-4cae-a6c5-dddff39d38f1"
devcenter_name="ade-sandbox-dc"
output_file="debug.json"

# Run the az CLI command
az devcenter dev environment show-logs-by-operation -o yaml --project-name "$project_name" -n "$environment_name" --operation-id "$operation_id" -d "$devcenter_name" > "$output_file"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq before running this script."
    exit 1
fi
# Combine all lines into a single line
combined_json=$(tr -d '\n' < "$output_file")

# Attempt to format the JSON using jq
if echo "$combined_json" | jq '.' > /dev/null 2>&1; then
    echo "$combined_json" | jq '.' > formatted_output.json
    echo "Successfully reformatted JSON. Output saved to 'formatted_output.json'."
else
    echo "Error: Failed to parse JSON. Please check the input file for syntax errors."
    exit 1
fi