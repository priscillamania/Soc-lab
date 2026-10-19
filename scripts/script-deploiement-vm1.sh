#!/bin/bash
# ==============================================================================
# SOC Lab — Déploiement et Préparation VM1 (Serveur SOC All-in-One)
# Wazuh Manager/Indexer/Dashboard + Graylog + OpenSearch + MongoDB + Grafana
# Utilisation : sudo bash scripts/script-deploiement-vm1.sh
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Erreur : Ce script doit être exécuté avec sudo."
    exit 1
fi

echo "================================================================="
echo " [SOC LAB] Préparation du Serveur SOC All-in-One (VM1)"
echo "================================================================="

echo "[1/7] Configuration du nom d'hôte..."
hostnamectl set-hostname soc-vm1

echo "[2/7] Mise à jour des dépôts..."
apt-get update -y

echo "[3/7] Installation des utilitaires de base..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    unzip \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    iproute2 \
    dnsutils \
    traceroute \
    tcpdump \
    openssl \
    ufw \
    pwgen

echo "[4/7] Installation officielle de Docker Engine & Docker Compose..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Ajout de l'utilisateur standard au groupe docker si présent
SUDO_USER_NAME="${SUDO_USER:-$USER}"
if [ -n "$SUDO_USER_NAME" ] && [ "$SUDO_USER_NAME" != "root" ]; then
    usermod -aG docker "$SUDO_USER_NAME" || true
fi

echo "[5/7] Création de l'arborescence SOC..."
mkdir -p /opt/soc-lab/scripts
mkdir -p /opt/soc-lab/wazuh
mkdir -p /opt/soc-lab/graylog
mkdir -p /opt/soc-lab/grafana
mkdir -p /opt/soc-lab/backups
mkdir -p /opt/soc-lab/logs

echo "[6/7] Configuration des paramètres Kernel (OpenSearch & Wazuh)..."
cat > /etc/sysctl.d/99-soc-lab.conf << 'EOF'
# Prérequis OpenSearch / Elasticsearch
vm.max_map_count=262144
fs.file-max=65536
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "[7/7] Vérification du système..."
echo ""
echo "Hostname : $(hostname)"
echo "Interfaces réseau :"
ip -br addr
echo "Paramètre vm.max_map_count : $(sysctl -n vm.max_map_count)"
echo "Version Docker : $(docker --version 2>/dev/null || echo 'en attente de reconnexion')"
echo "Version Docker Compose : $(docker compose version 2>/dev/null || echo 'en attente')"

echo "================================================================="
echo " [✓] Préparation VM1 terminée avec succès !"
echo "================================================================="
