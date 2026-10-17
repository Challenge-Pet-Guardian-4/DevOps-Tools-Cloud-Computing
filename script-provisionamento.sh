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

echo ""
echo "================================================================="
echo "⚙️  INICIANDO PROVISIONAMENTO DA INFRAESTRUTURA — SPRINT 4"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Região:           $LOCATION"
echo "  App Service Plan: $PLAN_NAME ($SKU Linux)"
echo "  Azure Web App:    $WEB_APP_NAME (Runtime Java 21)"
echo "================================================================="

# -----------------------------------------------------------------------------
# 1. Limpeza Prévia (Opcional - apaga o RG anterior se já existir)
# -----------------------------------------------------------------------------
if [ "$(az group exists --name "$RESOURCE_GROUP" 2>/dev/null)" = "true" ]; then
  echo ""
  echo "🧹 [LIMPEZA] Resource Group $RESOURCE_GROUP anterior detectado. Apagando..."
  az group delete --name "$RESOURCE_GROUP" --yes
  echo "✅ Resource Group anterior removido com sucesso."
fi

# -----------------------------------------------------------------------------
# 1. Criação do Resource Group
# -----------------------------------------------------------------------------
echo ""
echo "▶ [1/4] Verificando / Criando Resource Group ($RESOURCE_GROUP)..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# -----------------------------------------------------------------------------
# 2. Criação do App Service Plan (Linux)
# -----------------------------------------------------------------------------
echo ""
echo "▶ [2/4] Criando App Service Plan ($PLAN_NAME) em Linux ($SKU)..."
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --is-linux \
  --sku "$SKU" \
  --output table

# -----------------------------------------------------------------------------
# 3. Criação do Azure Web App (Runtime Java 21 Java SE)
# -----------------------------------------------------------------------------
echo ""
echo "▶ [3/4] Criando Azure Web App ($WEB_APP_NAME) com Java 21..."
az webapp create \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --runtime "JAVA:21-java21" \
  --output table

# -----------------------------------------------------------------------------
# 4. Configuração das Variáveis de Ambiente Seguras (App Settings)
# -----------------------------------------------------------------------------
echo ""
echo "▶ [4/4] Configurando Variáveis de Ambiente no Web App (Protegidas)..."

# Configura portas e URL base de infraestrutura
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
  echo "✅ Credenciais de banco aplicadas com sucesso via variáveis de ambiente."
else
  echo "ℹ️  Nota: Segredos de banco (ORACLE_PASSWORD, MONGODB_URI) devem ser gerenciados"
  echo "    diretamente no Portal do Azure (Configuration > Application settings)"
  echo "    ou via Pipeline Secrets do Azure DevOps para conformidade com DevSecOps."
fi

# -----------------------------------------------------------------------------
# 5. Informações Finais
# -----------------------------------------------------------------------------
WEB_APP_URL=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEB_APP_NAME" --query "defaultHostName" -o tsv)

echo ""
echo "================================================================="
echo "✅ INFRAESTRUTURA PROVISIONADA COM SUCESSO!"
echo "================================================================="
echo "🌐 URL do Web App: https://${WEB_APP_URL}"
echo "📖 Swagger UI:     https://${WEB_APP_URL}/swagger-ui/index.html"
echo "🩺 Health Check:   https://${WEB_APP_URL}/actuator/health"
echo "-----------------------------------------------------------------"
echo "🚀 PRÓXIMO PASSO: DEPLOY AUTOMÁTICO VIA AZURE DEVOPS"
echo "   Nome do Web App para o azure-pipelines.yml: $WEB_APP_NAME"
echo "   A esteira de CI/CD fará a compilação Gradle, testes JUnit e"
echo "   o deploy do .jar diretamente neste Web App a cada commit/push!"
echo "================================================================="