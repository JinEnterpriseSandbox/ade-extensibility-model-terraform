#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e # exit on error

EnvironmentState="$ADE_STORAGE/environment.tfstate"
EnvironmentPlan="/environment.tfplan"
EnvironmentVars="/environment.tfvars.json"

echo "$ADE_OPERATION_PARAMETERS" > $EnvironmentVars

# Set up Terraform AzureRM managed identity.
export ARM_USE_MSI=true
export ARM_CLIENT_ID=$ADE_CLIENT_ID
# Retrieve the client ID using the object ID
export ARM_CLIENT_ID=$(az ad sp show --id $ADE_CLIENT_ID --query appId -o tsv)
export ARM_TENANT_ID=$ADE_TENANT_ID
export ARM_SUBSCRIPTION_ID=$ADE_SUBSCRIPTION_ID

echo "=$(az ad sp show --id $ADE_CLIENT_ID --query appId -o tsv)"
# Ensure the remote state storage account is provided in the environment variables.
remote_state_rg=$(jq -r '.remote_state_rg' $EnvironmentVars)
remote_state_sa=$(jq -r '.remote_state_sa' $EnvironmentVars)
remote_state_container="tfstate"
remote_state_key="${ADE_ENVIRONMENT_TYPE}/${ADE_ENVIRONMENT}/${ADE_ENVIRONMENT_NAME}/.tfstate"

echo -e "\n>>> Remote State Configuration...\n"
echo "remote_state_rg: $remote_state_rg"
echo "remote_state_sa: $remote_state_sa"
echo "remote_state_container: $remote_state_container"
echo "remote_state_key: $remote_state_key"

if [[ -z "$remote_state_rg" || -z "$remote_state_sa" || -z "$remote_state_container" || -z "$remote_state_key" ]]; then
    echo "Error: One or more required remote state parameters are missing."
    echo "remote_state_rg: $remote_state_rg"
    echo "remote_state_sa: $remote_state_sa"
    echo "remote_state_container: $remote_state_container"
    echo "remote_state_key: $remote_state_key"
    exit 1
fi


echo -e "\n>>> Terraform Info...\n"
terraform -version

echo -e "\n>>> Initializing Terraform...\n"
terraform init -no-color \
    -backend-config="resource_group_name=$remote_state_rg"   \
    -backend-config="storage_account_name=$remote_state_sa"  \
    -backend-config="container_name=$remote_state_container" \
    -backend-config="key=$remote_state_key"

echo -e "\n>>> Creating Terraform Plan...\n"
export TF_VAR_resource_group_name=$ADE_RESOURCE_GROUP_NAME
export TF_VAR_ade_env_name=$ADE_ENVIRONMENT_NAME
export TF_VAR_env_name=$ADE_ENVIRONMENT_NAME
export TF_VAR_ade_subscription=$ADE_SUBSCRIPTION_ID
export TF_VAR_ade_location=$ADE_ENVIRONMENT_LOCATION
export TF_VAR_ade_environment_type=$ADE_ENVIRONMENT_TYPE

terraform plan -no-color -compact-warnings -refresh=true -lock=true -out=$EnvironmentPlan -var-file="$EnvironmentVars"

echo -e "\n>>> Applying Terraform Plan...\n"
terraform apply -no-color -compact-warnings -auto-approve -lock=true $EnvironmentPlan

# Outputs must be written to a specific file location.
# ADE expects data types array, boolean, number, object and string.
# Terraform outputs list, bool, number, map, set, string and null
# In addition, Terraform has type constraints, which allow for specifying the types of nested properties.
echo -e "\n>>> Generating outputs for ADE...\n"
tfout="$(terraform output -state=$EnvironmentState -json)"

# Convert Terraform output format to our internal format.
tfout=$(jq 'walk(if type == "object" then 
            if .type == "bool" then .type = "boolean" 
            elif .type == "list" then .type = "array" 
            elif .type == "map" then .type = "object" 
            elif .type == "set" then .type = "array" 
            elif (.type | type) == "array" then 
                if .type[0] == "tuple" then .type = "array" 
                elif .type[0] == "object" then .type = "object" 
                elif .type[0] == "set" then .type = "array" 
                else . 
                end 
            else . 
            end 
        else . 
        end)' <<< "$tfout")

echo "{\"outputs\": $tfout}" > $ADE_OUTPUTS
echo "Outputs successfully generated for ADE"