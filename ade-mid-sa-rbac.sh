storage_account_name="adesandboxtfstatewus2"
storage_account_resource_group="ade-sandbox-rg"


# Get the managed identity resource ID
echo -e "\n>>> Retrieving Managed Identity Resource ID...\n"
identity_resource_id=$(az identity show --name $ADE_MANAGED_IDENTITY_NAME --resource-group $ADE_RESOURCE_GROUP_NAME --query id -o tsv)

# Get the managed identity object ID
echo -e "\n>>> Retrieving Managed Identity Object ID...\n"
identity_object_id=$(az identity show --name $ADE_MANAGED_IDENTITY_NAME --resource-group $ADE_RESOURCE_GROUP_NAME --query principalId -o tsv)

# Get the storage account resource ID
echo -e "\n>>> Retrieving Storage Account Resource ID...\n"
storage_account_resource_id=$(az storage account show --name $storage_account_name --resource-group $storage_account_resource_group --query id -o tsv)
# Assign the Storage Blob Data Contributor role to the managed identity
echo -e "\n>>> Assigning Storage Blob Data Contributor Role...\n"



az role assignment create --assignee $identity_object_id --role "Storage Blob Data Contributor" --scope $storage_account_resource_id
