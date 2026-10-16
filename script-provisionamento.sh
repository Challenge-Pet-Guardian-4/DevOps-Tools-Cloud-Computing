#!/bin/bash
# =============================================================================
# PetGuardian — Provisionamento de Infraestrutura (Azure Web App)
# Disciplina: DevOps Tools & Cloud Computing — Sprint 4
# =============================================================================
# NOTA IMPORTANTE:
# Este script realiza o provisionamento inicial da infraestrutura (IaC).
# O BUILD, TESTES e DEPLOY da aplicação são realizados AUTOMATICAMENTE
# pela esteira de CI/CD do Azure DevOps (azure-pipelines.yml).
# =============================================================================

# Desativa conversão automática de caminhos no Git Bash (Windows)
export MSYS_NO_PATHCONV=1

# -----------------------------------------------------------------------------
# 0. Variáveis de Configuração
# -----------------------------------------------------------------------------
RESOURCE_GROUP="rg-petguardian"
LOCATION="eastus" # Região com alta disponibilidade e suporte a F1 (Free) / B1 (Basic)
PLAN_NAME="asp-petguardian"
SKU="B1" # B1 Dedicado para Java 17 Spring Boot (1.75 GB RAM)

# Sufixo dinâmico único baseado na assinatura da Azure para evitar conflito de nomes
SUB_SUFFIX=$(az account show --query 'id' -o tsv 2>/dev/null | tr -d '-' | cut -c1-8)
if [ -z "$SUB_SUFFIX" ]; then
  SUB_SUFFIX="01bd2f0c"
fi
WEB_APP_NAME="app-petguardian-${SUB_SUFFIX}"

# Credenciais e Conexões de Banco de Dados (Oracle FIAP + MongoDB Atlas)
ORACLE_URL="jdbc:oracle:thin:@//oracle.fiap.com.br:1521/orcl"
ORACLE_USER="RM561432"
ORACLE_PASS="301006"
MONGO_URI="mongodb+srv://enzookuizumifiap_db_user:PAEdhlPTE5QRMzjC@petguardian.agoderb.mongodb.net/petguardian?retryWrites=true&w=majority"
ADMIN_HASH='$2a$10$CGKqNEY043BjTqp9faNVoOodCnu3uU.rLNuuHR4XqwZTXjuShRf0G'

echo ""
echo "================================================================="
echo "⚙️  INICIANDO PROVISIONAMENTO DA INFRAESTRUTURA — SPRINT 4"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Região:           $LOCATION"
echo "  App Service Plan: $PLAN_NAME ($SKU Linux)"
echo "  Azure Web App:    $WEB_APP_NAME (Runtime Java 17)"
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
# 3. Criação do Azure Web App (Runtime Java 17 Java SE)
# -----------------------------------------------------------------------------
echo ""
echo "▶ [3/4] Criando Azure Web App ($WEB_APP_NAME) com Java 17..."
az webapp create \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --runtime "JAVA:17-java17" \
  --output table

# -----------------------------------------------------------------------------
# 4. Configuração das Variáveis de Ambiente Seguras (App Settings)
# -----------------------------------------------------------------------------
echo ""
echo "▶ [4/4] Configurando Variáveis de Ambiente no Web App (Protegidas)..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_APP_NAME" \
  --settings \
    ORACLE_URL="$ORACLE_URL" \
    ORACLE_USER="$ORACLE_USER" \
    ORACLE_PASSWORD="$ORACLE_PASS" \
    MONGODB_URI="$MONGO_URI" \
    ADMIN_BCRYPT_HASH="$ADMIN_HASH" \
    PORT="8080" \
    WEBSITES_PORT="8080" \
  --output table

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