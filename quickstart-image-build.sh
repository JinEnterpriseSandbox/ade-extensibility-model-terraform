#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Prompt for Registry if not provided
if [ -z "$1" ]; then
    read -p "Enter Azure Container Registry: " Registry
else
    Registry=$1
fi

# Prompt for Repository if not provided
if [ -z "$2" ]; then
    read -p "Enter Repository (default: ade): " Repository
    Repository=${Repository:-"ade"}
else
    Repository=$2
fi

# Prompt for Tag if not provided
if [ -z "$3" ]; then
    read -p "Enter Tag (default: latest): " Tag
    Tag=${Tag:-"latest"}
else
    Tag=$3
fi

echo "Logging into specified Azure Container Registry"
az login
az acr login -n $Registry

if [ $? -ne 0 ]; then
    echo "Failed to login to Azure Container Registry" >&2
    exit 1
fi

echo "Starting Docker Engine"
docker --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to start Docker Engine. Please make sure Docker is installed on this machine and available in PATH." >&2
    exit 1
fi

echo "Building Docker Image"
docker build -t "${Registry}.azurecr.io/${Repository}:${Tag}" .

if [ $? -ne 0 ]; then
    echo "Failed to build specified Docker Image. Please check the logs for more details." >&2
    exit 1
fi

echo "Pushing Docker Image to Azure Container Registry"
docker push "${Registry}.azurecr.io/${Repository}:${Tag}"

if [ $? -ne 0 ]; then
    echo "Failed to push specified Docker Image. Please check the logs for more details." >&2
    exit 1
fi

echo "Docker Image pushed successfully to ${Registry}.azurecr.io/${Repository}:${Tag}"
