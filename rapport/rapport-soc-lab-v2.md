```bash
mkdir -p rapport
cat > rapport/rapport-soc-lab.md <<'EOF'
# Rapport Technique - SOC Lab
## Mise en place d'un Centre Opérationnel de Sécurité (SOC) avec Wazuh, Grafana et Prometheus

---

### Informations du Projet

| Champ | Description |
| :--- | :--- |
| Projet | SOC Lab - Déploiement, Intégration, Détection et Automatisation |
| Module | Administration Systèmes & Cybersécurité |
| Établissement | [Nom de l'établissement] |
| Auteur | [Nom de l'étudiant] |
| Date | Octobre 2026 |
| Version | 1.0 |

---

## Sommaire

1. Introduction
2. Présentation des Outils Utilisés
3. Architecture de la Solution
4. Installation et Configuration
5. Explication des Configurations
6. Sécurité et Hardening
7. Intégration des Composants
8. Dashboards et Visualisation
9. Scénarios de Détection
10. Problèmes Rencontrés et Solutions
11. Automatisation avec Ansible
12. Bonus : Interface Web de Vulnérabilités
13. Conclusion
14. Annexes

---

## 1. Introduction

### 1.1 Contexte

Dans le cadre du module d'Administration Systèmes et Cybersécurité, il a été proposé de développer un Centre Opérationnel de Sécurité (SOC) fonctionnel, capable de :

- Collecter des événements de sécurité depuis plusieurs sources
- Détecter des activités malveillantes en temps réel
- Visualiser les données via des dashboards opérationnels
- Simuler et documenter des scénarios d'attaque
- Automatiser le déploiement et la configuration

### 1.2 Objectifs

| # | Objectif | État |
| :--- | :--- | :--- |
| 1 | Mettre en place une architecture de 3 VMs interconnectées | Terminé |
| 2 | Installer et configurer Wazuh (Manager, Indexer, Dashboard) | Terminé |
| 3 | Intégrer Grafana avec Wazuh et Prometheus | Terminé |
| 4 | Configurer des règles de détection personnalisées | Terminé |
| 5 | Exécuter des scénarios d'attaque et valider les détections | Terminé |
| 6 | Automatiser le déploiement avec Ansible | Terminé |
| 7 | Créer une interface web de visualisation des vulnérabilités (Bonus) | Terminé |
| 8 | Documenter le processus et présenter les résultats | Terminé |

### 1.3 Périmètre

Le projet a été développé dans un environnement isolé (laboratoire), avec des VMs configurées en réseau bridge. Tous les tests ont été réalisés de manière éthique et contrôlée.

---

## 2. Présentation des Outils Utilisés

Cette section décrit chaque outil déployé dans le laboratoire, sa fonction principale et pourquoi il a été choisi.

### 2.1 Wazuh - Plateforme de Détection et Réponse (XDR/EDR)

Wazuh est une plateforme open-source de sécurité qui combine SIEM et XDR. Elle collecte, analyse et corrèle les événements de sécurité.

Rôle dans le laboratoire :
- Détection d'intrusion (brute force, scan de ports)
- Surveillance de l'intégrité des fichiers (FIM)
- Analyse de vulnérabilités
- Conformité (SCA)
- Corrélation d'événements

Composants :

| Composant | Rôle |
| :--- | :--- |
| Wazuh Manager | Analyse les logs, applique les règles, génère les alertes |
| Wazuh Indexer | Base de données (OpenSearch) pour stocker les alertes |
| Wazuh Dashboard | Interface web pour visualiser et gérer |
| Wazuh Agent | Installé sur les machines surveillées (VM3) |

### 2.2 Filebeat - Transporteur de Logs

Filebeat est un shipper de logs léger qui lit les fichiers de logs et les envoie vers une destination.

Rôle dans le laboratoire :
- Sur la VM1 (Manager) : envoie les alertes vers l'Indexer
- Sur la VM3 (Agent) : envoie les logs Nginx et d'authentification

### 2.3 Grafana - Visualisation de Données

Grafana est une plateforme de visualisation et de monitoring pour créer des dashboards interactifs.

Rôle dans le laboratoire :
- Dashboards SOC : alertes Wazuh, état des agents
- Dashboards NOC : CPU, RAM, disque (via Prometheus)
- Alerting : notifications si seuils dépassés

### 2.4 Prometheus - Collecte de Métriques

Prometheus est un système de monitoring et d'alerte open-source. Il collecte des métriques à intervalles réguliers.

Rôle dans le laboratoire :
- Collecter les métriques système (CPU, RAM, disque)
- Fournir les données à Grafana
- Déclencher des alertes

### 2.5 Node Exporter - Exposeur de Métriques

Agent qui expose les métriques système Linux au format Prometheus.

Rôle dans le laboratoire :
- Exposer les métriques de la VM1 sur le port 9100
- Permettre à Prometheus de les collecter

### 2.6 Grafana Alloy - Collecte de Télémétrie Moderne

Grafana Alloy est le remplaçant moderne de l'agent Grafana (et de Promtail). Il collecte les métriques, logs et traces.

Rôle dans le laboratoire :
- Collecter les métriques et logs de manière unifiée
- Envoyer les données vers Grafana/Prometheus/Loki

### 2.7 Ansible - Automatisation (IaC)

Ansible est un outil d'automatisation (Infrastructure as Code). Il configure les VMs sans connexion manuelle.

Rôle dans le laboratoire :
- Automatiser le hardening
- Déployer des paquets et fichiers
- Gérer la configuration des VMs
- Exécuter les scénarios d'attaque

### 2.8 Docker - Conteneurisation

Plateforme de conteneurisation pour exécuter des applications isolées.

Rôle dans le laboratoire :
- Déployer rapidement des services (Grafana, Graylog)
- Isoler les dépendances

### 2.9 Rsyslog - Centralisation des Logs

Système de logging qui collecte et transmet les logs système.

Rôle dans le laboratoire :
- Sur la VM3 : envoyer les logs système vers le Manager ou Graylog
- Centraliser les logs

### 2.10 Auditd - Surveillance des Appels Système

Démon d'audit Linux qui surveille les appels système et accès aux fichiers.

Rôle dans le laboratoire :
- Surveiller /etc/passwd
- Fournir les logs à Wazuh pour alertes FIM

### 2.11 Fail2Ban - Protection contre les Attaques par Force Brute

Outil de prévention d'intrusion qui bannit les IPs après échecs d'authentification.

Rôle dans le laboratoire :
- Bannir les IPs après 3 échecs SSH
- Compléter Wazuh en agissant automatiquement

---

## 3. Architecture de la Solution

### 3.1 Diagramme de l'Infrastructure

```text
+-----------------------------------------------------------------------------+
|                           SOC LAB - INFRASTRUCTURE                          |
|                         Réseau : 192.168.1.0/24 (Bridge)                    |
+-----------------------------------------------------------------------------+

+-----------------------------------------------------------------------------+
|  VM1 - Wazuh Server (All-in-One)                                            |
|  IP : 192.168.1.54          OS : Ubuntu Server 22.04                        |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  |  Wazuh Indexer (OpenSearch)          Port : 9200 (HTTPS)              |  |
|  |  Wazuh Manager (API)                 Port : 55000                     |  |
|  |  Wazuh Dashboard (UI)                Port : 443 (HTTPS)               |  |
|  |  Filebeat                            (envoie les alertes)             |  |
|  |  Grafana                             Port : 3000                      |  |
|  |  Prometheus                          Port : 9090                      |  |
|  |  Node Exporter                       Port : 9100                      |  |
|  |  Nginx + PHP (Page Vulnérabilités)   Port : 8080                      |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
                                      |
                                      | Logs (1514/TCP)
                                      | API (55000/TCP)
                                      |
+-----------------------------------------------------------------------------+
|  VM3 - Cible / Agent Wazuh                                                  |
|  IP : 192.168.1.26 (ou 192.168.10.30)   OS : Ubuntu Server 22.04            |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  |  Wazuh Agent                         (ID : 002, actif)                |  |
|  |  Filebeat                            (envoie logs Nginx/auth)          |  |
|  |  rsyslog                             (envoie logs système)            |  |
|  |  Nginx                               Port : 80 (SSH ouvert)           |  |
|  |  auditd                              (surveille /etc/passwd)          |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
                                      |
                                      | Attaques simulées
                                      | (Hydra, nmap, brute force SSH)
                                      |
+-----------------------------------------------------------------------------+
|  VM2 - Attaquant                                                            |
|  IP : 192.168.1.20 (ou 192.168.10.20)   OS : Ubuntu Server 22.04            |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  |  Hydra                               (brute force SSH)                |  |
|  |  nmap                                (scan de ports)                  |  |
|  |  Ansible                             (automatisation)                 |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
```

### 3.2 Flux de Données

| Étape | Source | Destination | Protocole/Port |
| :--- | :--- | :--- | :--- |
| 1 | VM3 (Agent) | VM1 (Manager) | TCP 1514 |
| 2 | VM1 (Manager) | VM1 (Indexer) | HTTPS 9200 |
| 3 | VM1 (Filebeat) | VM1 (Indexer) | HTTPS 9200 |
| 4 | VM1 (Dashboard) | VM1 (Indexer) | HTTPS 9200 |
| 5 | VM1 (Grafana) | VM1 (Indexer) | HTTPS 9200 |
| 6 | VM1 (Prometheus) | VM1 (Node Exporter) | HTTP 9100 |
| 7 | VM2 (Ansible) | VM1 / VM3 | SSH 22 |

### 3.3 Spécifications des VMs

| VM | Fonction | CPU | RAM | Disque | OS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| VM1 | Wazuh Server | 4 vCPU | 8 Go | 50 Go | Ubuntu 22.04 |
| VM2 | Attaquant | 2 vCPU | 4 Go | 20 Go | Ubuntu 22.04 |
| VM3 | Cible/Agent | 2 vCPU | 4 Go | 20 Go | Ubuntu 22.04 |

---

## 4. Installation et Configuration

### 4.1 VM1 - Wazuh Server

#### 4.1.1 Prérequis

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg apt-transport-https
```

#### 4.1.2 Ajout du Dépôt Wazuh

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
  chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update
```

#### 4.1.3 Installation de Wazuh Indexer

```bash
sudo apt install -y wazuh-indexer

sudo mkdir -p /etc/wazuh-indexer/certs
sudo cp /home/vm1/wazuh-certificates/node-1.pem /etc/wazuh-indexer/certs/
sudo cp /home/vm1/wazuh-certificates/node-1-key.pem /etc/wazuh-indexer/certs/
sudo cp /home/vm1/wazuh-certificates/root-ca.pem /etc/wazuh-indexer/certs/

sudo chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs
sudo chmod 500 /etc/wazuh-indexer/certs
sudo chmod 400 /etc/wazuh-indexer/certs/*

sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer
```

#### 4.1.4 Installation de Wazuh Manager

```bash
sudo apt install -y wazuh-manager

sudo mkdir -p /var/ossec/etc/certs
sudo cp /home/vm1/wazuh-certificates/node-1.pem /var/ossec/etc/certs/
sudo cp /home/vm1/wazuh-certificates/node-1-key.pem /var/ossec/etc/certs/
sudo cp /home/vm1/wazuh-certificates/root-ca.pem /var/ossec/etc/certs/

sudo chown -R wazuh:wazuh /var/ossec/etc/certs
sudo chmod 500 /var/ossec/etc/certs
sudo chmod 400 /var/ossec/etc/certs/*

sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager
```

#### 4.1.5 Installation de Filebeat

```bash
sudo apt install -y filebeat

sudo curl -so /etc/filebeat/filebeat.yml \
  https://packages.wazuh.com/4.14/tpl/wazuh/filebeat/filebeat.yml

sudo nano /etc/filebeat/filebeat.yml
# Modifier : hosts: ["https://192.168.1.54:9200"]

sudo filebeat keystore create
echo 'admin' | sudo filebeat keystore add username --stdin --force
echo 'FN*kajRRSOLJJJvBsbn+lo4Ui5lMBA2r' | sudo filebeat keystore add password --stdin --force

sudo systemctl enable filebeat
sudo systemctl start filebeat
```

#### 4.1.6 Installation de Wazuh Dashboard

```bash
sudo apt install -y wazuh-dashboard

sudo mkdir -p /etc/wazuh-dashboard/certs
sudo cp /home/vm1/wazuh-certificates/dashboard.pem /etc/wazuh-dashboard/certs/
sudo cp /home/vm1/wazuh-certificates/dashboard-key.pem /etc/wazuh-dashboard/certs/
sudo cp /home/vm1/wazuh-certificates/root-ca.pem /etc/wazuh-dashboard/certs/

sudo chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs
sudo chmod 500 /etc/wazuh-dashboard/certs
sudo chmod 400 /etc/wazuh-dashboard/certs/*

sudo nano /etc/wazuh-dashboard/opensearch_dashboards.yml
# server.host: "0.0.0.0"
# opensearch.hosts: https://192.168.1.54:9200

sudo nano /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml
# url: https://192.168.1.54
# port: 55000
# username: wazuh-wui
# password: "PiZIP8lU17YvkF8ue.EcjEvIYSi?gEq8"

sudo systemctl daemon-reload
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
```

#### 4.1.7 Initialisation de la Sécurité de l'Indexer

```bash
export JAVA_HOME=/usr/share/wazuh-indexer/jdk
export PATH=$JAVA_HOME/bin:$PATH

/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /etc/wazuh-indexer/opensearch-security/ \
  -icl -nhnv \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -key /etc/wazuh-indexer/certs/admin-key.pem
```

### 4.2 VM1 - Grafana, Prometheus, Alloy et Ansible

#### 4.2.1 Installation de Docker

```bash
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world
```

#### 4.2.2 Installation de Grafana

```bash
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

#### 4.2.3 Installation de Prometheus et Node Exporter

```bash
sudo apt install -y prometheus prometheus-node-exporter

sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter

sudo nano /etc/prometheus/prometheus.yml
```

Ajouter :
```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

```bash
sudo systemctl restart prometheus
```

#### 4.2.4 Installation de Grafana Alloy

```bash
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt-get update && sudo apt-get install -y alloy

sudo systemctl start alloy
sudo systemctl status alloy
```

#### 4.2.5 Installation d'Ansible

```bash
sudo apt update
sudo apt install -y ansible

ansible --version
```

#### 4.2.6 Configuration de Grafana avec les Datasources

Datasource Wazuh :

| Champ | Valeur |
| :--- | :--- |
| Manager URL | https://192.168.1.54:55000 |
| Indexer URL | https://192.168.1.54:9200 |
| API username | wazuh-wui |
| API password | PiZIP8lU17YvkF8ue.EcjEvIYSi?gEq8 |
| Indexer username | admin |
| Indexer password | FN*kajRRSOLJJJvBsbn+lo4Ui5lMBA2r |
| Skip TLS verify | Coché |
| UID | wazuh |

Datasource Prometheus :

| Champ | Valeur |
| :--- | :--- |
| URL | http://192.168.1.54:9090 |
| Access | Server (default) |

### 4.3 VM3 - Agent Wazuh

#### 4.3.1 Installation de l'Agent

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
  chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  tee -a /etc/apt/sources.list.d/wazuh.list

sudo apt update
sudo apt install -y wazuh-agent
```

#### 4.3.2 Enregistrement de l'Agent auprès du Manager

Sur le Manager (VM1) :
```bash
/var/ossec/bin/manage_agents
# Appuyer sur 'A' pour ajouter
# Nom : vm3
# IP : 192.168.1.26
# Extraire la clé avec 'E'
```

Sur l'Agent (VM3) :
```bash
/var/ossec/bin/manage_agents
# Appuyer sur 'I' pour importer
# Coller la clé
```

#### 4.3.3 Configuration de l'Agent

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Ajouter :
```xml
<client>
  <server>
    <address>192.168.1.54</address>
  </server>
</client>
```

```bash
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

#### 4.3.4 Configuration de rsyslog, Filebeat et auditd

```bash
# Rsyslog
sudo nano /etc/rsyslog.conf
# Ajouter : *.* @192.168.1.54:514
sudo systemctl restart rsyslog

# Filebeat
sudo apt install -y filebeat
sudo nano /etc/filebeat/filebeat.yml
# output.logstash: hosts: ["192.168.1.54:5044"]
sudo systemctl enable filebeat
sudo systemctl start filebeat

# Auditd
sudo apt install -y auditd
sudo nano /etc/audit/rules.d/audit.rules
# Ajouter : -w /etc/passwd -p wa -k passwd_changes
sudo service auditd restart
```

---

## 5. Explication des Configurations

### 5.1 Wazuh Indexer (/etc/wazuh-indexer/opensearch.yml)

| Paramètre | Valeur | Explication |
| :--- | :--- | :--- |
| network.host | 192.168.1.54 | Écoute sur l'interface réseau |
| node.name | node-1 | Identifie le nœud |
| cluster.initial_master_nodes | ["node-1"] | Nœud maître initial |
| plugins.security.ssl... | Chemins vers certificats | TLS obligatoire |

### 5.2 Wazuh Manager (/var/ossec/etc/ossec.conf)

| Section | Explication |
| :--- | :--- |
| <indexer> | Indique où envoyer les alertes (Indexer) |
| <syslog_output> | Envoie les alertes à Graylog (optionnel) |
| <active-response> | Bloque automatiquement les IPs malveillantes |

### 5.3 Filebeat (/etc/filebeat/filebeat.yml)

| Paramètre | Explication |
| :--- | :--- |
| output.elasticsearch.hosts | Destination (Indexer) |
| protocol: https | Communication chiffrée |
| ssl.certificate_authorities | CA pour valider l'Indexer |

### 5.4 Grafana (Datasources)

| Paramètre | Explication |
| :--- | :--- |
| Manager URL | API du Manager pour les agents |
| Indexer URL | Indexer pour les alertes |
| UID: wazuh | Les dashboards pré-construits cherchent cette UID |

### 5.5 Prometheus (/etc/prometheus/prometheus.yml)

| Paramètre | Explication |
| :--- | :--- |
| scrape_configs | Définit les cibles à collecter |
| targets: ['localhost:9100'] | Node Exporter pour les métriques système |

### 5.6 Auditd (/etc/audit/rules.d/audit.rules)

| Règle | Explication |
| :--- | :--- |
| -w /etc/passwd -p wa -k passwd_changes | Surveille les modifications de /etc/passwd |

### 5.7 Fail2Ban (/etc/fail2ban/jail.local)

| Paramètre | Explication |
| :--- | :--- |
| maxretry = 3 | 3 échecs avant bannissement |
| bantime = 24h | Durée du bannissement |

### 5.8 Règles Wazuh (/var/ossec/etc/rules/local_rules.xml)

```xml
<group name="local,syslog,sshd,authentication_failures">
  <rule id="100001" level="10" frequency="5" timeframe="120">
    <if_matched_sid>5716</if_matched_sid>
    <same_source_ip />
    <description>Custom Alert: 5 or more failed SSH logins from the same IP.</description>
    <group>authentication_failures,brute_force</group>
  </rule>
</group>
```

| Élément | Explication |
| :--- | :--- |
| id="100001" | ID personnalisé (100000-109999 réservé) |
| level="10" | Sévérité élevée |
| frequency="5" timeframe="120" | 5 occurrences en 120 secondes |
| <same_source_ip /> | Même IP source |

### 5.9 Active Response (ossec.conf)

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5710</rules_id>
  <timeout>1800</timeout>
</active-response>
```

| Élément | Explication |
| :--- | :--- |
| firewall-drop | Commande pour bloquer via iptables |
| rules_id 5710 | Déclenché sur échec SSH |
| timeout 1800 | Bloque pendant 30 minutes |

---

## 6. Sécurité et Hardening

### 6.1 SSH Hardening

```bash
sudo nano /etc/ssh/sshd_config
```

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

```bash
sudo systemctl restart sshd
```

### 6.2 Firewall UFW

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 9200/tcp
sudo ufw allow 55000/tcp
sudo ufw allow 1514/tcp
sudo ufw allow 514/udp
sudo ufw allow 5044/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp
sudo ufw allow 8080/tcp
sudo ufw enable
```

### 6.3 Fail2Ban

```bash
sudo apt install -y fail2ban
sudo nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
port = 2222
maxretry = 3
bantime = 24h
```

```bash
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

### 6.4 Politique de Mots de Passe

```bash
sudo nano /etc/security/pwquality.conf
```

```
minlen = 12
minclass = 4
maxrepeat = 3
```

### 6.5 Kernel Hardening

```bash
sudo nano /etc/sysctl.d/99-hardening.conf
```

```
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
```

```bash
sudo sysctl -p /etc/sysctl.d/99-hardening.conf
```

### 6.6 Désactivation des Services Inutiles

```bash
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
```

---

## 7. Intégration des Composants

### 7.1 Flux de Données

```text
[VM3 - Agent Wazuh] 
    | (1) Envoie les logs via TCP 1514
    v
[VM1 - Wazuh Manager]
    | (2) Analyse les logs
    | (3) Génère des alertes
    v
[VM1 - Wazuh Indexer]
    | (4) Stocke les alertes
    v
[VM1 - Wazuh Dashboard] <-- (5) Lit les alertes
[VM1 - Grafana]         <-- (6) Lit les alertes + métriques Prometheus
[VM1 - Nginx + PHP]     <-- (7) Interroge l'Indexer pour les vulnérabilités
```

### 7.2 Rôle de Chaque Composant

| Composant | Rôle |
| :--- | :--- |
| Wazuh Agent | Collecte les logs |
| Wazuh Manager | Analyse et corrèle |
| Filebeat | Transporte les alertes |
| Wazuh Indexer | Stocke et indexe |
| Wazuh Dashboard | Affiche les alertes |
| Grafana | Visualise alertes + métriques |
| Prometheus | Collecte les métriques |
| Node Exporter | Expose les métriques |
| Nginx + PHP | Affiche les vulnérabilités via une page web |

---

## 8. Dashboards et Visualisation

### 8.1 Dashboards Wazuh (Pré-construits)

| Dashboard | Description |
| :--- | :--- |
| Security Overview | Vue d'ensemble des alertes |
| Agent Status | État des agents |
| Vulnerabilities | Vulnérabilités détectées |
| File Integrity (FIM) | Modifications de fichiers |
| SCA | Configuration de sécurité |

### 8.2 Dashboards Personnalisés (Grafana)

| Dashboard | Description | Source |
| :--- | :--- | :--- |
| Vue générale des logs | Volume, sources, sévérité | Wazuh |
| Alertes Wazuh Sécurité | Alertes par criticité | Wazuh |
| Surveillance SSH | Tentatives SSH, IPs | Wazuh |
| Métriques Système | CPU, RAM, disque | Prometheus |
| Vulnérabilités | CVE, sévérité, correctifs | Wazuh |

---

## 9. Scénarios de Détection

### 9.1 Scénario A - Brute Force SSH

Commande (VM2) :
```bash
for i in $(seq 1 15); do
  ssh root@192.168.1.26 -p 22 -o ConnectTimeout=2 2>/dev/null
done
```

Détection : Wazuh rule.id 5710 (level >= 10), Grafana pic, Fail2Ban bannit.

### 9.2 Scénario B - Modification de Fichier Critique

Commande (VM3) :
```bash
sudo echo "test" >> /etc/passwd
```

Détection : Wazuh rule.id 550 (level >= 7). Pour une détection en temps réel, ajouter realtime="yes" dans ossec.conf sur /etc/passwd.

### 9.3 Scénario C - Scan de Ports

Commande (VM2) :
```bash
nmap -sS -p 192.168.1.26
```

Détection : Wazuh détecte le scan, logs dans Graylog (si configuré).

---

## 10. Problèmes Rencontrés et Solutions

### 10.1 Problèmes d'Installation

| # | Problème | Cause | Solution |
| :--- | :--- | :--- | :--- |
| 1 | Unable to locate package wazuh-indexer | Dépôt non configuré | Ajouter la clé GPG et le dépôt Wazuh |
| 2 | apt-key: command not found | Commande obsolète | Utiliser gpg --dearmor au lieu de apt-key |
| 3 | Release file is not valid yet | Horloge de la VM désynchronisée | sudo ntpdate pool.ntp.org |
| 4 | Certificats introuvables | Répertoire non créé | mkdir -p /etc/wazuh-indexer/certs |

### 10.2 Problèmes de Configuration

| # | Problème | Cause | Solution |
| :--- | :--- | :--- | :--- |
| 5 | Error opening log file '/var/log/wazuh-indexer/gc.log' | Répertoire de logs inexistant | mkdir -p /var/log/wazuh-indexer |
| 6 | ClusterManagerNotDiscoveredException | Configuration cluster multi-nœuds | Supprimer les références à node-2 et node-3 |
| 7 | Connection refused sur le port 55000 | API du Manager non démarrée | systemctl restart wazuh-manager |
| 8 | Invalid admin user credentials | Mot de passe admin incorrect | Utiliser les certificats : -c admin.pem -k admin-key.pem |

### 10.3 Problèmes d'Intégration

| # | Problème | Cause | Solution |
| :--- | :--- | :--- | :--- |
| 9 | Grafana : authentication failed | Mot de passe wazuh-wui obsolète | Mettre à jour wazuh.yml avec le mot de passe du wazuh-passwords.txt |
| 10 | Grafana : Indexer URL 0.0.0.0 | Adresse d'écoute au lieu de destination | Modifier pour https://192.168.1.54:9200 |
| 11 | Grafana : No data dans les dashboards | UID du datasource incorrect | Modifier l'UID pour wazuh |
| 12 | Dashboard : server is not ready yet
