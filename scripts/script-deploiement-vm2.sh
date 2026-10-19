#!/bin/bash
# ==============================================================================
# SOC Lab — Déploiement et Préparation VM2 (Machine d'Attaque / Pentest)
# Utilisation : sudo bash scripts/script-deploiement-vm2.sh
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Erreur : Ce script doit être exécuté avec sudo."
    exit 1
fi

echo "================================================================="
echo " [SOC LAB] Préparation de la Machine d'Attaque (VM2)"
echo "================================================================="

echo "[1/4] Configuration hostname..."
hostnamectl set-hostname soc-attacker-vm2

echo "[2/4] Mise à jour des dépôts et paquets..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    unzip \
    jq \
    net-tools \
    iproute2 \
    dnsutils \
    traceroute \
    tcpdump \
    tshark \
    nmap \
    hydra \
    nikto \
    whois

echo "[3/4] Préparation des répertoires et dictionnaires d'attaque..."
mkdir -p /opt/soc-lab/wordlists
mkdir -p /opt/soc-lab/scripts
mkdir -p /opt/soc-lab/results

# Création d'une wordlist ciblée pour le test Hydra
cat << 'EOF' > /opt/soc-lab/wordlists/passwd.txt
admin
password
123456
12345678
qwerty
toor
root
ubuntu
vm3
password123
letmein
welcome
supersecret
P@ssw0rd2026
EOF

# Extraction de rockyou.txt si l'archive existe
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
if [ -f "${DIR}/docs/rockyou.txt.zip" ]; then
    echo "[*] Décompression de rockyou.txt..."
    unzip -o "${DIR}/docs/rockyou.txt.zip" -d /opt/soc-lab/wordlists/ || true
fi

echo "[4/4] Installation des scripts de simulation d'attaque..."
cp -f "${DIR}"/scripts/attack-*.sh /opt/soc-lab/scripts/ 2>/dev/null || true
chmod +x /opt/soc-lab/scripts/*.sh 2>/dev/null || true

echo "================================================================="
echo " [✓] VM2 prête pour les simulations d'attaque (Nmap & Hydra) !"
echo "================================================================="
