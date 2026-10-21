
#!/usr/bin/env bash
set -euo pipefail

RG="rg-trunfo-atomico"
VM="vm-trunfo-atomico"
LOCATION="brazilsouth"

echo "Conferindo assinatura Azure..."
az account show --output table

echo "Criando grupo de recursos..."
az group create \
  --name "$RG" \
  --location "$LOCATION"

echo "Criando VM Ubuntu..."
az vm create \
  --resource-group "$RG" \
  --name "$VM" \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

echo "Consultando o IP público..."
az vm show -d \
  --resource-group "$RG" \
  --name "$VM" \
  --query publicIps \
  --output tsv
