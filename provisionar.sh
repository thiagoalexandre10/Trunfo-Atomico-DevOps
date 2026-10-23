
#!/usr/bin/env bash
set -euo pipefail

RG="rg-trunfo-atomico"
VM="vm-trunfo-atomico"
LOCATION="spaincentral"
SIZE="Standard_B2ls_v2"
USER_NAME="azureuser"

echo "Verificando assinatura Azure..."
az account show --output table

echo "Criando grupo de recursos em Spain Central..."
az group create \
  --name "$RG" \
  --location "$LOCATION"

echo "Criando maquina virtual Ubuntu..."
az vm create \
  --resource-group "$RG" \
  --name "$VM" \
  --image Ubuntu2204 \
  --size "$SIZE" \
  --admin-username "$USER_NAME" \
  --generate-ssh-keys

echo "Consultando IP publico..."
az vm show -d \
  --resource-group "$RG" \
  --name "$VM" \
  --query publicIps \
  --output tsv

echo "Provisionamento concluido."
