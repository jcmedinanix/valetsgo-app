#!/bin/bash
# =============================================================
# ValetsGo DevOps — Script de aprovisionamiento de infraestructura
# Soporta: OCI (Always Free) | AWS (Free Tier) | GCP (Always Free)
# =============================================================


set -e

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funciones de utilidad ---
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
ask()     { echo -e "${CYAN}[?]${NC} $1"; }

# --- Verificar que no se ejecuta como root ---
if [ "$EUID" -eq 0 ]; then
  error "No ejecutes este script como root. Usa tu usuario normal: bash setup.sh"
fi



# --- Banner ---
clear
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║       ValetsGo DevOps — Setup Wizard         ║"
echo "  ║   Aprovisionamiento automático de servidor   ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================
# PASO 1 — Verificar dependencias
# =============================================================
info "Verificando dependencias necesarias..."

check_dep() {
  if ! command -v "$1" &> /dev/null; then
    error "$1 no está instalado. Instálalo antes de continuar."
  else
    success "$1 encontrado"
  fi
}

check_dep terraform
check_dep git
check_dep curl
check_dep ssh-keygen
check_dep jq

echo ""

# =============================================================
# PASO 2 — Elegir nube
# =============================================================
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
echo "  ¿En qué nube deseas desplegar el servidor?"
echo "  1) OCI  — Oracle Cloud Infrastructure (Always Free, sin límite de tiempo)"
echo "  2) AWS  — Amazon Web Services         (Free Tier, 12 meses)"
echo "  3) GCP  — Google Cloud Platform       (Always Free, sin límite de tiempo)"
echo "  4) Salir"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
ask "Ingresa el número de tu elección [1-3]:"
read -r CLOUD_CHOICE

case $CLOUD_CHOICE in
  1) CLOUD="oci"   CLOUD_NAME="Oracle Cloud Infrastructure" ;;
  2) CLOUD="aws"   CLOUD_NAME="Amazon Web Services" ;;
  3) CLOUD="gcp"   CLOUD_NAME="Google Cloud Platform" ;;
  4) info "Saliendo del wizard. ¡Hasta luego!"; exit 0 ;;
  *) error "Opción inválida. Ejecuta el script de nuevo." ;;
esac

success "Nube seleccionada: $CLOUD_NAME"
echo ""

# Directorio de trabajo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/$CLOUD"

if [ ! -d "$TF_DIR" ]; then
  error "No se encontró la carpeta $TF_DIR"
fi

# =============================================================
# PASO 3 — Clave SSH
# =============================================================
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
info "Configuración de clave SSH"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"

DEFAULT_KEY="$HOME/.ssh/valetsgo_key"

if [ -f "${DEFAULT_KEY}.pub" ]; then
  warn "Ya existe una clave SSH en ${DEFAULT_KEY}.pub"
  ask "¿Deseas usar esa clave existente? [s/n]:"
  read -r USE_EXISTING_KEY
  if [[ "$USE_EXISTING_KEY" =~ ^[Ss]$ ]]; then
    SSH_KEY_PATH="${DEFAULT_KEY}.pub"
    success "Usando clave existente: $SSH_KEY_PATH"
  else
    info "Generando nueva clave SSH..."
    ssh-keygen -t rsa -b 4096 -f "$DEFAULT_KEY" -N "" -C "valetsgo-devops"
    SSH_KEY_PATH="${DEFAULT_KEY}.pub"
    success "Clave generada en $DEFAULT_KEY"
  fi
else
  info "Generando clave SSH nueva en $DEFAULT_KEY..."
  ssh-keygen -t rsa -b 4096 -f "$DEFAULT_KEY" -N "" -C "valetsgo-devops"
  SSH_KEY_PATH="${DEFAULT_KEY}.pub"
  success "Clave generada en $DEFAULT_KEY"
fi

echo ""
warn "Clave pública (necesitarás esto para OCI/GCP si lo pide la consola):"
cat "$SSH_KEY_PATH"
echo ""

# =============================================================
# PASO 4 — Credenciales según la nube elegida
# =============================================================
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
info "Configuración de credenciales para $CLOUD_NAME"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"

TFVARS_FILE="$TF_DIR/terraform.tfvars"

case $CLOUD in

  # --- OCI ---
  oci)
    echo ""
    echo "  Para obtener estos datos en OCI:"
    echo "  → Compartment ID: Menú → Identity → Compartments → copia el OCID"
    echo "  → Availability Domain: Menú → Compute → Instances → Create Instance"
    echo "  → Image ID: al crear instancia, elige Ubuntu 22.04 y copia el OCID"
    echo "  → Región: revisa la URL de tu consola OCI (ej: sa-saopaulo-1)"
    echo ""

    ask "Región OCI (ej: sa-saopaulo-1):"
    read -r OCI_REGION
    ask "Compartment ID (ocid1.tenancy.oc1..xxx):"
    read -r OCI_COMPARTMENT
    ask "Availability Domain (ej: XkLi:SA-SAOPAULO-1-AD-1):"
    read -r OCI_AD
    ask "Image ID Ubuntu 22.04 para tu región (ocid1.image.oc1...):"
    read -r OCI_IMAGE

    cat > "$TFVARS_FILE" << EOF
region              = "$OCI_REGION"
compartment_id      = "$OCI_COMPARTMENT"
availability_domain = "$OCI_AD"
image_id            = "$OCI_IMAGE"
ssh_public_key_path = "$SSH_KEY_PATH"
EOF
    ;;

  # --- AWS ---
  aws)
    echo ""
    echo "  Para obtener estos datos en AWS:"
    echo "  → Access Key: IAM → Users → tu usuario → Security Credentials → Create access key"
    echo "  → AMI ID: EC2 → Launch Instance → busca 'Ubuntu 22.04' → copia el AMI ID"
    echo "  → Región: revisa la esquina superior derecha de la consola AWS"
    echo ""

    ask "Región AWS (ej: us-east-1):"
    read -r AWS_REGION
    ask "Access Key ID:"
    read -r AWS_ACCESS_KEY
    ask "Secret Access Key:"
    read -rs AWS_SECRET_KEY
    echo ""
    ask "AMI ID Ubuntu 22.04 para tu región (ej: ami-0c7217cdde317cfec para us-east-1):"
    read -r AWS_AMI

    cat > "$TFVARS_FILE" << EOF
region              = "$AWS_REGION"
access_key          = "$AWS_ACCESS_KEY"
secret_key          = "$AWS_SECRET_KEY"
ami_id              = "$AWS_AMI"
ssh_public_key_path = "$SSH_KEY_PATH"
EOF
    ;;

  # --- GCP ---
  gcp)
    echo ""
    echo "  Para obtener estos datos en GCP:"
    echo "  → Project ID: consola GCP → barra superior → nombre del proyecto"
    echo "  → Credentials JSON: IAM → Service Accounts → Create → JSON key → descarga"
    echo "  → Región recomendada para Always Free: us-central1 o us-west1"
    echo ""

    ask "Project ID de GCP:"
    read -r GCP_PROJECT
    ask "Ruta al archivo JSON de credenciales (ej: ~/.gcp/credentials.json):"
    read -r GCP_CREDS
    ask "Región GCP (ej: us-central1):"
    read -r GCP_REGION

    cat > "$TFVARS_FILE" << EOF
project_id          = "$GCP_PROJECT"
credentials_file    = "$GCP_CREDS"
region              = "$GCP_REGION"
ssh_public_key_path = "$SSH_KEY_PATH"
EOF
    ;;
esac

success "Archivo terraform.tfvars generado en $TFVARS_FILE"
echo ""

# =============================================================
# PASO 5 — Terraform init y apply
# =============================================================
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
info "Iniciando Terraform en $TF_DIR"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"

cd "$TF_DIR"

info "Ejecutando terraform init..."
terraform init -upgrade

echo ""
info "Ejecutando terraform plan..."
terraform plan -var-file="terraform.tfvars"

echo ""
ask "¿Deseas aplicar el plan y crear el servidor? [s/n]:"
read -r APPLY_CONFIRM

if [[ ! "$APPLY_CONFIRM" =~ ^[Ss]$ ]]; then
  warn "Aplicación cancelada. El plan fue generado pero no ejecutado."
  warn "Para aplicarlo manualmente: cd $TF_DIR && terraform apply"
  exit 0
fi

info "Ejecutando terraform apply..."
terraform apply -var-file="terraform.tfvars" -auto-approve

# =============================================================
# PASO 6 — Capturar IP pública
# =============================================================
echo ""
info "Obteniendo IP pública del servidor..."

SERVER_IP=$(terraform output -raw instance_public_ip 2>/dev/null)

if [ -z "$SERVER_IP" ]; then
  error "No se pudo obtener la IP pública. Revisa el output de Terraform."
fi

success "Servidor creado con IP: $SERVER_IP"
echo ""

# Esperar a que el servidor esté listo (Docker tarda ~60s en instalarse)
info "Esperando 90 segundos para que el servidor termine de configurarse..."
for i in $(seq 1 9); do
  echo -ne "  ${CYAN}[$i/9]${NC} Configurando servidor...\r"
  sleep 10
done
echo ""
success "Servidor listo"
echo ""


# =============================================================
# PASO 7 — Configurar secrets de GitHub
# =============================================================
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
info "Configuración de secrets en GitHub"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
echo ""
echo "  Necesitamos configurar 5 secrets en tu repositorio de GitHub"
echo "  para que el pipeline CI/CD pueda desplegar automáticamente."
echo ""
ask "Tu usuario de GitHub (ej: jcmedinanix):"
read -r GH_USER
ask "Nombre del repositorio (ej: valetsgo-app):"
read -r GH_REPO
ask "Token de GitHub con permisos 'repo' y 'workflow' (ghp_...):"
read -rs GH_TOKEN
echo ""
if [ -z "$GH_TOKEN" ]; then
  error "Token de GitHub vacío. Ejecuta el script de nuevo."
fi
success "Token de GitHub recibido"
ask "Tu usuario de Docker Hub:"
read -r DH_USER
ask "Token de Docker Hub (Account Settings → Security → New Access Token):"
read -rs DH_TOKEN
echo ""
if [ -z "$DH_TOKEN" ]; then
  error "Token de Docker Hub vacío. Ejecuta el script de nuevo."
fi
success "Token de Docker Hub recibido"
# Función para configurar un secret en GitHub via API
set_github_secret() {
  local SECRET_NAME=$1
  local SECRET_VALUE=$2
  # Obtener la public key del repo para cifrar el secret
  local KEY_RESPONSE
  KEY_RESPONSE=$(curl -s \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GH_USER/$GH_REPO/actions/secrets/public-key")
  local KEY_ID
  KEY_ID=$(echo "$KEY_RESPONSE" | jq -r '.key_id')
  local PUBLIC_KEY
  PUBLIC_KEY=$(echo "$KEY_RESPONSE" | jq -r '.key')


  # Cifrar el secret con la public key del repo usando Python
  local ENCRYPTED
  ENCRYPTED=$(python3 -c "
import base64, sys
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PublicKey
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import nacl.public, nacl.encoding

public_key_bytes = base64.b64decode('$PUBLIC_KEY')
public_key = nacl.public.PublicKey(public_key_bytes)
sealed_box = nacl.public.SealedBox(public_key)
encrypted = sealed_box.encrypt('$SECRET_VALUE'.encode())
print(base64.b64encode(encrypted).decode())
" 2>/dev/null)

  if [ -z "$ENCRYPTED" ]; then
    # Fallback: instalar pynacl si no está
    pip3 install pynacl --quiet 2>/dev/null
    ENCRYPTED=$(python3 -c "
import base64, nacl.public, nacl.encoding
public_key = nacl.public.PublicKey(base64.b64decode('$PUBLIC_KEY'))
sealed_box = nacl.public.SealedBox(public_key)
encrypted = sealed_box.encrypt('$SECRET_VALUE'.encode())
print(base64.b64encode(encrypted).decode())
")
  fi

  # Subir el secret cifrado
  local HTTP_CODE
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GH_USER/$GH_REPO/actions/secrets/$SECRET_NAME" \
    -d "{\"encrypted_value\":\"$ENCRYPTED\",\"key_id\":\"$KEY_ID\"}")

  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
    success "Secret $SECRET_NAME configurado"
  else
    warn "No se pudo configurar $SECRET_NAME (HTTP $HTTP_CODE) — configúralo manualmente en GitHub"
  fi
}

info "Configurando secrets en $GH_USER/$GH_REPO..."
echo ""

# Leer la clave privada SSH
SSH_PRIVATE_KEY=$(cat "${DEFAULT_KEY}" | base64 -w 0)

set_github_secret "DOCKERHUB_USERNAME" "$DH_USER"         || true
set_github_secret "DOCKERHUB_TOKEN"    "$DH_TOKEN"        || true
set_github_secret "SSH_HOST"           "$SERVER_IP"       || true
set_github_secret "SSH_USER"           "ubuntu"           || true
set_github_secret "SSH_KEY"            "$SSH_PRIVATE_KEY" || true

echo ""

# =============================================================
# PASO 8 — Preparar el servidor
# =============================================================
info "Esperando que el servidor acepte conexiones SSH..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$DEFAULT_KEY" ubuntu@"$SERVER_IP" "echo ok" 2>/dev/null; do
  echo -ne "  Reintentando conexion SSH...\r"
  sleep 5
done
success "Servidor accesible por SSH"

info "Esperando que Docker este listo en el servidor..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$DEFAULT_KEY" ubuntu@"$SERVER_IP" "docker info > /dev/null 2>&1" 2>/dev/null; do
  echo -ne "  Esperando Docker daemon...\r"
  sleep 10
done
success "Docker listo"

info "Creando carpeta y levantando contenedores en el servidor..."
ssh -o StrictHostKeyChecking=no -i "$DEFAULT_KEY" ubuntu@"$SERVER_IP" bash << 'REMOTE'
  mkdir -p ~/valetsgo-app
  cd ~/valetsgo-app
  curl -o docker-compose.yml https://raw.githubusercontent.com/jcmedinanix/valetsgo-app/main/docker-compose.yml
  curl -o nginx.conf https://raw.githubusercontent.com/jcmedinanix/valetsgo-app/main/nginx.conf
  docker-compose pull
  docker-compose up -d
REMOTE
success "Contenedores levantados correctamente"

echo ""

# =============================================================
# PASO 9 — Resumen final
# =============================================================
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║           INSTALACIÓN COMPLETADA             ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${GREEN}Servidor:${NC}       $CLOUD_NAME"
echo -e "  ${GREEN}IP pública:${NC}     $SERVER_IP"
echo ""
echo -e "  ${GREEN}URLs del sistema (disponibles tras el primer deploy):${NC}"
echo -e "  → Aplicación:   http://$SERVER_IP"
echo -e "  → Dashboard:    http://$SERVER_IP/dashboard"
echo -e "  → Monitoreo:    http://$SERVER_IP:3001"
echo ""
echo -e "  ${GREEN}Próximo paso:${NC}"
echo -e "  Haz un git push a main para activar el primer despliegue automático:"
echo -e "  ${CYAN}git push origin main${NC}"
echo ""
echo -e "  ${GREEN}Credenciales del dashboard:${NC}"
echo -e "  Usuario:    admin"
echo -e "  Contraseña: (la que configuraste en docker-compose.yml)"
echo ""
echo -e "  ${YELLOW}Guarda estos datos en un lugar seguro:${NC}"
echo -e "  Clave privada SSH: $DEFAULT_KEY"
echo -e "  IP del servidor:   $SERVER_IP"
echo ""

