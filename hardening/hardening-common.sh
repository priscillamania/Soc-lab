#!/bin/bash
# ==========================================
# SCRIPT DE RENFORCEMENT (HARDENING) POUR LABORATOIRE SOC (Personnalisé)
# ==========================================

echo "[*] Lancement du renforcement du système..."

# 1. Mise à jour du système
sudo apt update && sudo apt upgrade -y

# 2. Renforcement de la configuration SSH (ATTENTION : ne modifiez pas le port, sauf nécessité absolue)
# Nous conservons le port 22 pour éviter de compromettre votre accès actuel.
# En revanche, nous désactivons la connexion de l'utilisateur « root » par mot de passe (en autorisant uniquement l'authentification par clé) et nous interdisons les mots de passe vides. sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 3. Pare-feu UFW (Ports pour le laboratoire SOC)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH pour votre accès (si vous utilisez le port 22, conservez-le ; si vous utilisez le port 2222, adaptez la commande)
sudo ufw allow 22/tcp comment 'SSH Admin'

# Ouvrir les ports pour Wazuh et les services SOC
sudo ufw allow 443/tcp comment 'Wazuh Dashboard'
sudo ufw allow 3000/tcp comment 'Grafana'
sudo ufw allow 9090/tcp comment 'Prometheus'
sudo ufw allow 9100/tcp comment 'Node Exporter'
sudo ufw allow 9200/tcp comment 'Wazuh Indexer'
sudo ufw allow 55000/tcp comment 'Wazuh API'
sudo ufw allow 1514/tcp comment 'Wazuh Agent'
sudo ufw allow 514/udp comment 'Syslog'
sudo ufw allow 5044/tcp comment 'Filebeat/Beats'

# Activer UFW sans demander de confirmation
sudo ufw --force enable

#4. Fail2Ban (configuré pour ne pas bannir votre réseau interne)
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port = 22
maxretry = 5
bantime = 3600
# Ignorer votre réseau local pour éviter de vous auto-bannir
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24
EOF
sudo systemctl restart fail2ban

# 5. Durcissement du noyau (protection contre les attaques réseau)
sudo tee /etc/sysctl.d/99-soc-hardening.conf > /dev/null <<EOF
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl -p /etc/sysctl.d/99-soc-hardening.conf

# 6. Politique de mots de passe (pour les nouveaux utilisateurs uniquement)
sudo apt install -y libpam-pwquality
sudo sed -i 's/^# minlen.*/minlen = 10/' /etc/security/pwquality.conf
sudo sed -i 's/^# minclass.*/minclass = 3/' /etc/security/pwquality.conf

# 7. Désactivation des services inutiles (s'ils sont présents)
sudo systemctl disable bluetooth 2>/dev/null
sudo systemctl disable cups 2>/dev/null
sudo systemctl disable avahi-daemon 2>/dev/null

echo "[+] Durcissement effectué avec succès !" echo "[!] Vérifiez que SSH fonctionne toujours avant de fermer votre session."
