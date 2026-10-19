#!/bin/bash
# ==============================================================================
# SOC Lab — Déploiement et Préparation VM3 (Machine Cible / Victime)
# Services : Wazuh Agent + Nginx + Rsyslog + Filebeat
# Utilisation : sudo bash scripts/script-deploiement-vm3.sh
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Erreur : Ce script doit être exécuté avec sudo."
    exit 1
fi

SOC_VM1_IP="192.168.10.10"

echo "================================================================="
echo " [SOC LAB] Déploiement de la Machine Cible (VM3)"
echo " Serveur SOC (VM1) : ${SOC_VM1_IP}"
echo "================================================================="

echo "[1/6] Configuration du nom d'hôte..."
hostnamectl set-hostname soc-victim-vm3

echo "[2/6] Mise à jour et installation des paquets système..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    rsyslog \
    nginx

# Démarrage de Nginx
systemctl enable --now nginx

echo "[3/6] Installation et configuration de Filebeat..."
install -m 0755 -d /usr/share/keyrings
if [ ! -f /usr/share/keyrings/elastic-keyring.gpg ]; then
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
fi
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y filebeat

# Configuration de Filebeat pour Graylog Beats Input (port 5044)
cat << EOF > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: filestream
  id: nginx-logs
  enabled: true
  paths:
    - /var/log/nginx/*.log

- type: filestream
  id: auth-logs
  enabled: true
  paths:
    - /var/log/auth.log

output.logstash:
  hosts: ["${SOC_VM1_IP}:5044"]
EOF

systemctl enable --now filebeat
systemctl restart filebeat

echo "[4/6] Configuration de Rsyslog vers Graylog..."
cat << EOF > /etc/rsyslog.d/60-graylog.conf
# Redirection de tous les logs système vers Graylog sur VM1 (port UDP 514)
*.* @${SOC_VM1_IP}:514
EOF

systemctl restart rsyslog

echo "[5/6] Installation de l'Agent Wazuh..."
if [ ! -f /usr/share/keyrings/wazuh.gpg ]; then
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
    chmod 644 /usr/share/keyrings/wazuh.gpg
fi
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

apt-get update -y
WAZUH_MANAGER="${SOC_VM1_IP}" DEBIAN_FRONTEND=noninteractive apt-get install -y wazuh-agent

# Démarrage de l'agent Wazuh
systemctl daemon-reload
systemctl enable --now wazuh-agent

echo "[6/6] Vérification des statuts des services sur VM3..."
echo "Nginx       : $(systemctl is-active nginx)"
echo "Rsyslog     : $(systemctl is-active rsyslog)"
echo "Filebeat    : $(systemctl is-active filebeat)"
echo "Wazuh-Agent : $(systemctl is-active wazuh-agent)"

echo "================================================================="
echo " [✓] VM3 déployée et configurée pour envoyer ses logs à VM1 !"
echo "================================================================="
