#!/bin/bash
# Provisionamento de Infraestrutura (Azure Web App) - PetGuardian

export MSYS_NO_PATHCONV=1

# Configuração da infraestrutura
RESOURCE_GROUP="rg-petguardian"
LOCATION="eastus"
PLAN_NAME="asp-petguardian"
SKU="B1"
WEB_APP_NAME="${WEB_APP_NAME:-app-petguardian-01bd2f0c}"

# Conexões de banco injetadas via ambiente
ORACLE_URL="${ORACLE_URL:-jdbc:oracle:thin:@//oracle.fiap.com.br:1521/orcl}"
ORACLE_USER="${ORACLE_USER:-RM561432}"
ORACLE_PASS="${ORACLE_PASSWORD:-}"
MONGO_URI="${MONGODB_URI:-}"
ADMIN_HASH="${ADMIN_BCRYPT_HASH:-}"

echo "⚙️  Provisionando infraestrutura Azure ($RESOURCE_GROUP / $WEB_APP_NAME)..."

# 1. Resource Group
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# 2. App Service Plan
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --is-linux \
  --sku "$SKU" \
  --output table

# 3. Azure Web App
az webapp create \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --runtime "JAVA:21-java21" \
  --output table

# 4. App Settings (portas e URLs base)
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_APP_NAME" \
  --settings \
    PORT="8080" \
    WEBSITES_PORT="8080" \
    ORACLE_URL="$ORACLE_URL" \
    ORACLE_USER="$ORACLE_USER" \
  --output table

# Injeta credenciais se fornecidas na sessão
if [ -n "$ORACLE_PASS" ] && [ -n "$MONGO_URI" ]; then
  az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME" \
    --settings \
      ORACLE_PASSWORD="$ORACLE_PASS" \
      MONGODB_URI="$MONGO_URI" \
      ADMIN_BCRYPT_HASH="$ADMIN_HASH" \
    --output table
fi

WEB_APP_URL=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEB_APP_NAME" --query "defaultHostName" -o tsv)

echo "✅ Infraestrutura pronta: https://${WEB_APP_URL}"