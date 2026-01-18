# Script to update Front Door to point to v2
# Run this manually after testing v2

# Update Front Door origin
az afd origin update \
    --profile-name smartfactory-fd \
    --origin-group-name smartfactory-origin-group \
    --origin-name smartfactory-origin \
    --host-name smartfactoryml-api-v2.azurewebsites.net \
    --resource-group smartfactory-rg

Write-Host "Front Door updated to use v2 endpoint"
