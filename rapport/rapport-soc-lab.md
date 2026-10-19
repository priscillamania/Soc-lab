# RAPPORT TECHNIQUE D'INFRASTRUCTURE SOC (SECURITY OPERATIONS CENTER)
## Déploiement et Intégration de Wazuh, Graylog, Grafana et Plateforme Offensive

**Module :** Administration Systèmes & Cybersécurité  
**Niveau :** BTS SIO / Licence Pro / BUT Informatique  
**Auteur :** Priscilla M. (@priscillamania)  
**Entreprise mandataire :** SecureNet Solutions  
**Date du projet :** Octobre 2026  
**Durée de réalisation :** 3 mois  

---

## TABLE DES MATIÈRES
1. Contexte d'Entreprise et Objectifs Stratégiques du SOC
2. Architecture Réseau et Évolution du Projet
3. Matrice de Sécurité et Durcissement des Systèmes (Hardening)
4. Déploiement de l'Infrastructure Centrale SOC (VM1)
5. Configuration de la Plateforme d'Attaque (VM2)
6. Déploiement et Instrumentation de la Machine Cible (VM3)
7. Intégration des Flux et Centralisation des Logs
8. Tableaux de Bord de Supervision Opérationnelle (Grafana)
9. Scénarios de Test d'Intrusion et Analyse de Détection
10. Analyse des Incidents et Cartographie MITRE ATT&CK
11. Difficultés Rencontrées, Diagnostics et Résolutions
12. Bilan, Préconisations et Perspectives d'Évolution

---

## 1. Contexte d'Entreprise et Objectifs Stratégiques du SOC

### 1.1 Contexte Professionnel chez SecureNet Solutions
Dans le cadre de ses activités de prestation de services managés en cybersécurité pour les Petites et Moyennes Entreprises (PME), la société SecureNet Solutions est mandatée pour concevoir, 
déployer et valider une plateforme complète de détection et de supervision des incidents de sécurité (SOC — Security Operations Center).

La majorité des PME clientes est confrontée à une recrudescence d'attaques ciblant directement leurs infrastructures de production : 
tentatives d'intrusion par force brute sur les services d'administration (SSH), scans de vulnérabilités automatisés, et altérations non autorisées de fichiers de configuration critiques. 
Face à ces menaces, ces structures souffrent d'un déficit majeur de visibilité, leurs journaux d'événements restant cloisonnés sur chaque machine sans corrélation ni analyse proactive.

### 1.2 Objectifs Techniques et Opérationnels
Le projet vise à répondre à quatre objectifs majeurs :
- **Centralisation exhaustive des journaux** : Collecter l'ensemble des événements système (syslog), des traces applicatives (serveur Web Nginx) et des journaux d'authentification (auth.log)
 via des protocoles fiables et standardisés.
- **Détection des menaces en temps réel** : Implémenter un système de détection d'intrusion basé sur les hôtes (HIDS / SIEM) capable de corréler les événements, d'évaluer les niveaux de gravité et de lever 
des alertes immédiates.
- **Visualisation et Tableaux de Bord Actionnables** : Offrir aux analystes SOC une interface de restitution claire, dynamique et synthétique facilitant l'évaluation rapide de la posture de sécurité.
- **Validation Offensive Contrôlée** : Conduire des simulations d'attaques réalistes depuis un réseau externe hostile pour éprouver la chaîne complète de détection, du capteur jusqu'au tableau de bord.

---

## 2. Architecture Réseau et Évolution du Projet

### 2.1 Évolution Stratégique de l'Architecture (Consigne Verbale)
Le sujet initialement fourni prévoyait une répartition des rôles où la machine VM2 hébergeait la pile Graylog, tandis que les tests offensifs devaient être exécutés depuis une machine externe non détaillée.

Afin de disposer d'un laboratoire 100% autonome, rigoureux et représentatif d'une infrastructure d'entreprise, une modification concertée a été actée :
- **Convergence SOC sur la VM1 (All-in-One)** : L'ensemble de la plateforme défensive (SIEM Wazuh, Centralisateur de logs Graylog, Moteurs d'indexation OpenSearch/MongoDB, 
et Visualisation Grafana) est regroupé sur la machine VM1 (soc-vm1).
- **Affectation de la VM2 en Machine d'Attaque Dédiée** : La machine VM2 (soc-attacker-vm2) est désormais consacrée exclusivement aux tests offensifs (Nmap, Hydra, Dictionnaires), 
isolée dans un réseau externe hostile.
- **Machine Cible VM3 (Victime)** : La machine VM3 (soc-victim-vm3) héberge les services applicatifs de production (Nginx, SSH) et les sondes de collecte (Agent Wazuh, Filebeat, Rsyslog).

### 2.2 Schéma Détaillé de l'Architecture Réseau Cible

```
                      +---------------------------------------+
                      |       VM2 -- Machine Attaquant        |
                      |            192.168.20.20/24           |
                      |       (Hydra, Nmap, Kali Tools)       |
                      +-------------------+-------------------+
                                          |
                        Réseau Externe    | (Segment VMnet3 : 192.168.20.0/24)
                                          v
                      +---------------------------------------+
                      |         VM3 -- Machine Cible          |
                      |   ens34 (Externe) : 192.168.20.30/24  |
                      |   ens33 (Interne) : 192.168.10.30/24  |
                      |    (Nginx, SSH:22/2222, Sondes SOC)   |
                      +-------------------+-------------------+
                                          |
                        Réseau SOC Interne| (Segment VMnet2 : 192.168.10.0/24)
                                          v
                      +---------------------------------------+
                      |       VM1 -- Serveur SOC Unifié       |
                      |            192.168.10.10/24           |
                      |  +---------------------------------+  |
                      |  | Wazuh Manager + Indexer + WUI   |  |
                      |  | Graylog 5.2 + OpenSearch + Mongo|  |
                      |  | Grafana Dashboards              |  |
                      |  +---------------------------------+  |
                      +---------------------------------------+
```

### 2.3 Justification de la Topologie Dual-Homed (DMZ Réaliste)
La machine cible VM3 est pourvue de deux interfaces réseau distinctes :
- **Interface externe ens34 (192.168.20.30)** : Connectée au réseau VMnet3 partagé avec l'attaquant VM2. Elle simule la face publique d'un serveur exposé sur Internet ou en DMZ.
- **Interface interne ens33 (192.168.10.30)** : Connectée au réseau sécurisé VMnet2 réservé au SOC. C'est via cette interface isolée que VM3 achemine la télémétrie vers VM1.

Cette approche garantit que l'attaquant VM2 ne peut en aucun cas scanner, perturber ou attaquer directement le serveur de supervision VM1.

### 2.4 Matrice d'Adressage et Spécifications des Machines

| Machine | Hostname | Interfaces & Adresses IP | RAM / Disque | Rôles & Services Hébergés |
|---|---|---|---|---|
| **VM1** | `soc-vm1` | `ens33 : 192.168.10.10/24` | 6 Go / 60 Go | Wazuh Manager, Wazuh Indexer, Dashboard, Graylog, OpenSearch, MongoDB, Grafana |
| **VM2** | `soc-attacker-vm2` | `ens33 : 192.168.20.20/24` | 2 Go / 20 Go | Simulateur d'attaques, Hydra, Nmap, Wordlists Rockyou/Passwd |
| **VM3** | `soc-victim-vm3` | `ens33 : 192.168.10.30/24`<br>`ens34 : 192.168.20.30/24` | 2 Go / 20 Go | Serveur de production Nginx, SSH (22 et 2222), Agent Wazuh, Filebeat, Rsyslog |

---

## 3. Matrice de Sécurité et Durcissement des Systèmes (Hardening)

Conformément aux exigences de la Partie 1.2 (15 points d'évaluation), un programme d'automatisation du durcissement a été implémenté au travers des scripts du dossier `hardening/`.

### 3.1 Détail des 7 Mesures de Sécurité Obligatoires

#### Mesure 1 : Durcissement du Service SSH (3 points)
- Déplacement du port standard d'écoute de 22 vers **2222**.
- Interdiction stricte du login sous le compte root : `PermitRootLogin no`.
- Interdiction de l'authentification par mot de passe standard pour l'administration : `PasswordAuthentication no`.
- Authentification par paire de clés asymétriques obligatoire : `PubkeyAuthentication yes`.
- Limitation du nombre maximal de tentatives : `MaxAuthTries 3`.
- *Exception opérationnelle sur VM3 :* Comme stipulé dans l'énoncé, le port 22 de la VM3 reste ouvert et accessible avec mot de passe pour servir de vecteur de détection des attaques de brute force.

#### Mesure 2 : Pare-feu UFW Stricte par Défaut (3 points)
- Blocage par défaut de tout trafic entrant : `ufw default deny incoming`.
- Autorisation sélective et nominative des ports indispensables selon la machine.

#### Mesure 3 : Système de Prévention des Intrusions Fail2Ban (2 points)
- Surveillance continue du journal `/var/log/auth.log`.
- Règle de bannissement automatique : tout hôte distant échouant à s'authentifier 3 fois consécutives (`maxretry = 3`) sur une période de 10 minutes (`findtime = 600s`) 
est banni pour une durée de 24 heures (`bantime = 86400s`).

#### Mesure 4 : Politique de Mots de Passe Renforcée (2 points)
- Intégration du module PAM `libpam-pwquality` dans `/etc/security/pwquality.conf`.
- Critères appliqués : longueur minimale de 12 caractères (`minlen = 12`), au moins 1 chiffre (`dcredit = -1`), 1 majuscule (`ucredit = -1`), 1 minuscule (`lcredit = -1`), 
1 symbole (`ocredit = -1`), et un maximum de 3 caractères consécutifs identiques (`maxrepeat = 3`).

#### Mesure 5 : Renforcement du Noyau Linux via sysctl (2 points)
- Activation de la protection anti-usurpation (Reverse Path Filtering) : `rp_filter = 1`.
- Activation des SYN Cookies pour neutraliser les attaques par déni de service SYN Flood : `tcp_syncookies = 1`.
- Rejet des paquets de redirection ICMP : `accept_redirects = 0` et `send_redirects = 0`.
- Randomisation de l'espace d'adressage mémoire (ASLR niveau 2) : `kernel.randomize_va_space = 2`.
- Restriction d'accès aux messages du noyau : `kernel.dmesg_restrict = 1`.
- Élévation de la mémoire virtuelle pour les conteneurs de recherche : `vm.max_map_count = 262144`.

#### Mesure 6 : Surveillance Système Auditd (2 points)
- Surveillance en lecture/écriture/modification des fichiers d'authentification critiques :
  - `/etc/passwd` (étiquette `-k fichier_critique`)
  - `/etc/shadow` (étiquette `-k fichier_critique`)
  - `/etc/sudoers` et `/etc/sudoers.d/` (étiquette `-k fichier_critique`)
  - `/etc/group` (étiquette `-k fichier_critique`)

#### Mesure 7 : Désactivation des Services Superflus (1 point)
- Arrêt et désactivation systématique des démons présentant une surface d'attaque inutile sur des serveurs : serveur d'impression `cups`, démon de découverte réseau `avahi-daemon`, et pile sans fil `bluetooth`.

### 3.2 Matrice d'Ouverture des Flux Réseau Pare-feu (UFW)

| Machine | Port / Protocole | Service Associé | Justification Opérationnelle |
|---|---|---|---|
| **VM1** | `2222 / TCP` | SSH Admin | Administration système sécurisée par clé |
| **VM1** | `9000 / TCP` | Graylog Web | Interface graphique d'administration des logs |
| **VM1** | `3000 / TCP` | Grafana | Tableaux de bord de supervision visuelle |
| **VM1** | `5601 / TCP` | Wazuh Dashboard | Console d'exploitation des alertes et conformité |
| **VM1** | `1514 / UDP` | Wazuh Agent Data | Réception chiffrée des alertes des agents |
| **VM1** | `1515 / TCP` | Wazuh Enrollment | Enrôlement automatique des nouveaux agents |
| **VM1** | `55000 / TCP` | Wazuh Manager API | Communication API sécurisée (Dashboard/Grafana) |
| **VM1** | `514, 5140 / UDP` | Syslog Inputs | Réception des logs système et alertes relayées |
| **VM1** | `5044 / TCP` | Beats Input | Réception des flux Filebeat (Nginx, Auth) |
| **VM1** | `12201 / UDP` | GELF Input | Réception des journaux conteneurisés |
| **VM2** | `2222 / TCP` | SSH Admin | Administration système sécurisée |
| **VM2** | `Sortant : ALL` | Outils Pentest | Permet à Hydra et Nmap d'émettre vers VM3 |
| **VM3** | `2222 / TCP` | SSH Admin | Administration système sécurisée par clé |
| **VM3** | `22 / TCP` | SSH Vulnérable | Cible intentionnelle pour la détection du brute force |
| **VM3** | `80 / TCP` | Nginx HTTP | Serveur Web cible soumis aux scans |

---

## 4. Déploiement de l'Infrastructure Centrale SOC (VM1)

### 4.1 Préparation du Système et Conteneurisation
La machine VM1 est configurée via le script `scripts/script-deploiement-vm1.sh` qui installe Docker Engine, le plugin Docker Compose, les utilitaires d'analyse réseau, et configure le paramètre noyau 
`vm.max_map_count=262144`.

### 4.2 Architecture de la Pile Docker All-in-One
Le fichier `docker-compose-vm1.yml` unifie 7 microservices orchestrés au sein du réseau Docker bridge isolé `soc_net` :
1. **wazuh.indexer** (image : `wazuh/wazuh-indexer:4.7.2`) : Moteur de stockage et de recherche analytique des événements de sécurité.
2. **wazuh.manager** (image : `wazuh/wazuh-manager:4.7.2`) : Cœur d'analyse HIDS, moteur de règles et de corrélation, décodage des alertes et gestion des agents.
3. **wazuh.dashboard** (image : `wazuh/wazuh-dashboard:4.7.2`) : Interface utilisateur officielle Wazuh WUI accessible sur le port 5601.
4. **grafana** (image : `grafana/grafana:latest`) : Moteur de métriques et tableaux de bord opérationnels SOC (port 3000).
5. **soc-mongo** (image : `mongo:6.0`) : Base de données NoSQL dédiée au stockage des métadonnées, configurations et utilisateurs de Graylog.
6. **soc-opensearch** (image : `opensearchproject/opensearch:2.19.6`) : Nœud de données d'indexation haute performance pour les messages de logs ingérés par Graylog.
7. **soc-graylog** (image : `graylog/graylog:5.2`) : Serveur de centralisation, de parsing et de gestion des entrées Syslog, GELF et Beats (port 9000).

---

## 5. Configuration de la Plateforme d'Attaque (VM2)

La machine VM2 est déployée avec `scripts/script-deploiement-vm2.sh` afin d'intégrer les arsenaux offensifs indispensables :
- **Hydra** (`hydra v9.3`) : Outil parallélisé d'attaque par dictionnaire sur les protocoles réseau (SSH, HTTP, FTP).
- **Nmap** (`nmap v7.80+`) : Scanner de ports et de services réseau à haute furtivité (SYN Stealth Scan `-sS`).
- **Jeux de Dictionnaires** : Dictionnaire spécifique `passwd.txt` contenant les mots de passe de test courants, et décompression de la wordlist `rockyou.txt` pour les scénarios exhaustifs.
- **Scripts d'Attaque Automatisés** : `attack-scenario-a-hydra.sh` et `attack-scenario-c-nmap.sh`.

---

## 6. Déploiement et Instrumentation de la Machine Cible (VM3)

Déployée via `scripts/script-deploiement-vm3.sh`, la machine VM3 reçoit :
- **Serveur Web Nginx** : Activé sur le port 80 standard, générant les journaux d'accès `/var/log/nginx/access.log` et d'erreurs `/var/log/nginx/error.log`.
- **Agent Wazuh (v4.7.2)** : Enrôlé auprès du Manager `192.168.10.10`, surveillant l'intégrité des fichiers (FIM/Syscheck), les règles d'audit, et les journaux système.
- **Rsyslog Daemon** : Configuré avec `/etc/rsyslog.d/60-graylog.conf` pour expédier immédiatement chaque ligne système vers le collecteur Graylog sur `192.168.10.10:514/UDP`.
- **Filebeat (v8.x)** : Déployé pour lire en continu `/var/log/nginx/*.log` et `/var/log/auth.log` et les acheminer vers l'entrée Beats de Graylog sur `192.168.10.10:5044/TCP`.

---

## 7. Intégration des Flux et Centralisation des Logs

### 7.1 Architecture d'Ingestion Graylog
Trois entrées (Inputs) sont déclarées et surveillées dans l'interface de Graylog :
1. **Syslog UDP Input (Port 514 / 5140)** : Reçoit les messages noyau, cron, auth, et système de la VM3 ainsi que les alertes relayées par Wazuh.
2. **Beats TCP Input (Port 5044)** : Reçoit les événements d'accès HTTP Nginx et les logs d'authentification structurés transmis par Filebeat.
3. **GELF UDP Input (Port 12201)** : Prêt à ingérer les logs au format Graylog Extended Log Format.

### 7.2 Forwarding des Alertes Wazuh vers Graylog
Pour décloisonner la supervision, le module `syslog_output` est activé dans le fichier `/var/ossec/etc/ossec.conf` du Wazuh Manager. Chaque alerte de niveau supérieur ou égal à 3 
est automatiquement encapsulée en JSON et transmise par Syslog à Graylog, permettant une corrélation unifiée.

---

## 8. Tableaux de Bord de Supervision Opérationnelle (Grafana)

Trois tableaux de bord dédiés ont été élaborés et provisionnés automatiquement pour l'équipe SOC :

### 8.1 Dashboard 1 — Vue Générale des Logs
- **Volume horaire (Time Series)** : Histogramme temporel du nombre de logs ingérés par heure pour identifier les anomalies de débit.
- **Top 10 des sources (Bar Chart)** : Classement des machines et conteneurs émetteurs selon le champ `agent.name`.
- **Distribution de la Sévérité (Pie Chart)** : Répartition visuelle en camembert des logs selon les niveaux de criticité (Notice, Info, Warning, Error, Critical).

### 8.2 Dashboard 2 — Alertes Wazuh Sécurité
- **Jauge de Gravité** : Indicateur à aiguille comptabilisant les alertes de criticité élevée (niveau $\ge 7$) avec seuillage dynamique (vert < 10, orange 10-25, rouge > 50).
- **Tableau Top 5 Règles** : Affichage synthétique des 5 identifiants de règles Wazuh les plus déclenchées avec description claire.
- **Timeline en Temps Réel (Logs Panel)** : Flux défilant en continu présentant les alertes détaillées avec horodatage, nom d'hôte et règle associée.

### 8.3 Dashboard 3 — Surveillance SSH & Détection d'Attaque
- **Fréquence par minute (Time Series)** : Courbe en temps réel des échecs d'authentification SSH.
- **Matrice des Attaquants (Table)** : Extraction automatique de l'IP source (`data.srcip`) et des noms d'utilisateurs testés (`data.dstuser`).
- **Seuil d'Alerte Intégré** : Règle de notification visuelle passant la jauge au rouge dès que les échecs dépassent 5 tentatives par minute.

---

## 9. Scénarios de Test d'Intrusion et Analyse de Détection

### 9.1 Scénario A — Attaque par Force Brute SSH (5 points)

#### Procédure d'Exécution :
Depuis la machine VM2 (`192.168.20.20`), exécution de l'outil Hydra ciblant le port d'écoute SSH standard de VM3 :
```bash
hydra -l root -P /opt/soc-lab/wordlists/passwd.txt -t 4 -vV ssh://192.168.20.30:22
```
Complétée par la boucle de simulation rapide :
```bash
for i in $(seq 1 15); do
  ssh root@192.168.20.30 -p 22 -o ConnectTimeout=2 2>/dev/null
done
```

#### Chaîne de Détection et Résultats Validés :
1. **Détection HIDS (Wazuh)** : L'agent Wazuh analyse en temps réel `/var/log/auth.log` et transmet les échecs au Manager. Celui-ci déclenche la règle critique **Rule ID 5710** (Level 10 : 
*sshd: Multiple authentication failures / brute force attack*).
2. **Réponse Active Locale (Fail2Ban sur VM3)** : Dès le 3ème échec consécutif, la prison sshd de Fail2Ban insère une règle iptables/nftables interdisant l'adresse IP `192.168.20.20` pour 24 heures.
 Vérifié avec `sudo fail2ban-client status sshd`.
3. **Journalisation Graylog** : Les messages d'échec `Failed password for invalid user root from 192.168.20.20 port ... ssh2` sont immédiatement visibles dans le module Search de Graylog.
4. **Visualisation Grafana** : Le Dashboard 3 enregistre le pic de 15 échecs consécutifs et l'alerte visuelle vire au rouge.

### 9.2 Scénario B — Altération d'un Fichier Système Critique (5 points)

#### Procédure d'Exécution :
Sur la machine VM3, injection d'une commande d'altération du fichier des comptes utilisateurs :
```bash
sudo bash scripts/scenario-b-auditd.sh
# Commande sous-jacente : echo "test" >> /etc/passwd
```

#### Chaîne de Détection et Résultats Validés :
1. **Capture Noyau par Auditd** : La règle d'audit `-w /etc/passwd -p wa -k fichier_critique` intercepte l'appel système et consigne l'événement avec les identifiants de l'auteur (`uid=0`, `comm="bash"`).
2. **Alerte d'Intégrité Wazuh (FIM)** : Le module Syscheck identifie la modification d'empreinte cryptographique et la divergence de taille du fichier `/etc/passwd`. 
Déclenchement de la règle **Rule ID 550** (Level 7 : *Integrity checksum changed*).
3. **Restitution Console** : L'alerte est immédiatement mise en exergue dans le Wazuh Dashboard (section Integrity Monitoring).

### 9.3 Scénario C — Scan de Ports Réseau Nmap (5 points)

#### Procédure d'Exécution :
Depuis la machine VM2, lancement d'un balayage furtif SYN complet des 65535 ports :
```bash
sudo nmap -sS -p- -T4 192.168.20.30
```

#### Chaîne de Détection et Résultats Validés :
1. **Détection Pare-feu & Système** : Les milliers de paquets TCP SYN envoyés sur des ports fermés provoquent la génération d'alertes RST/UFW.
2. **Wazuh** : Détection des anomalies réseau et des tentatives d'accès aux services fermés.
3. **Graylog** : Réception immédiate des journaux de rejet UFW et des requêtes tronquées enregistrées par Nginx sur le port 80.

---

## 10. Analyse des Incidents et Cartographie MITRE ATT&CK

Pour professionnaliser l'analyse SOC, chaque scénario d'attaque a été mis en correspondance avec la matrice standard internationale MITRE ATT&CK pour les systèmes Linux :

| Scénario d'Attaque | Tactique MITRE ATT&CK | Technique & ID | Mécanisme de Détection SOC | Règle Déclenchée |
|---|---|---|---|---|
| **Scénario A (Hydra)** | Credential Access | Brute Force: Password Guessing (`T1110.001`) | Corrélation des échecs auth.log par Wazuh | Wazuh Rule 5710 (Level 10) |
| **Scénario A (Fail2Ban)** | Defense Evasion | Execution: Block IP Response (`T1562.001`) | Invalidation automatique de la connexion | Prison Fail2Ban sshd |
| **Scénario B (/etc/passwd)** | Persistence / Privilege Escalation | Account Manipulation (`T1098`) / Modify OS File (`T1565`) | Surveillance d'intégrité FIM + Auditd | Wazuh Rule 550 (Level 7) |
| **Scénario C (Nmap Scan)** | Reconnaissance / Discovery | Network Service Scanning (`T1046`) | Détection des paquets non sollicités | UFW Drop Logs + Wazuh Decoders |

---

## 11. Difficultés Rencontrées, Diagnostics et Résolutions

### Problème 1 : Conflit de Port 9200 sur VM1
- **Diagnostic** : Wazuh Indexer et OpenSearch (pour Graylog) sont tous deux basés sur la technologie OpenSearch/Elasticsearch et tentent par défaut d'écouter sur le port hôte 9200.
- **Résolution** : Le conteneur `soc-opensearch` de Graylog a été configuré pour dialoguer exclusivement au sein du réseau Docker bridge `soc_net` via son nom DNS de conteneur 
(`http://soc-opensearch:9200`), sans exposer le port 9200 sur l'hôte, et en proposant le port 9201 en secours local.

### Problème 2 : Gestion de l'Empreinte Mémoire RAM
- **Diagnostic** : Le lancement simultané de 7 conteneurs incluant deux moteurs Java (OpenSearch) risquait d'entraîner l'arrêt brutal des services par 
l'Out-Of-Memory Killer (OOM Killer) sur une machine virtuelle de 6 Go.
- **Résolution** : Configuration stricte des allocations de tas (Heap) Java : `-Xms512m -Xmx512m` pour Wazuh Indexer et `-Xms1g -Xmx1g` pour Graylog OpenSearch. 
Application impérative de `vm.max_map_count=262144`.

### Problème 3 : Conciliation du Durcissement SSH et des Tests de Détection
- **Diagnostic** : Le script de durcissement standard fermait le port 22 et interdisait les mots de passe, rendant impossible la démonstration de l'attaque Hydra sur le port 22.
- **Résolution** : Mise en place d'une configuration personnalisée sur VM3 : port 2222 réservé à l'administration légitime par clé, et port 22 maintenu actif comme honeypot de détection supervisé par Fail2Ban.

### Problème 4 : Isolement Réseau de l'Attaquant
- **Diagnostic** : Placer VM2 dans un sous-réseau séparé tout en permettant l'attaque sur VM3 sans exposer VM1.
- **Résolution** : Implémentation du mode Dual-Homed sur VM3 (deux cartes réseau reliant VMnet2 et VMnet3), garantissant un cloisonnement strict entre la zone d'attaque et la zone de supervision.

---

## 12. Bilan, Préconisations et Perspectives d'Évolution

### 12.1 Bilan Opérationnel
Le projet a permis de concevoir, déployer et valider une architecture SOC moderne, résiliente et parfaitement documentée. Les 100 points du barème d'évaluation sont rigoureusement couverts :
- Déploiement et durcissement des 3 machines virtuelles (Partie 1 : 40 pts).
- Intégration complète des collecteurs et dashboards (Partie 2 : 35 pts).
- Démonstration des 3 scénarios d'attaque et de réponse (Partie 3 : 15 pts).
- Documentation technique et diaporama professionnel (Partie 4 : 10 pts).

### 12.2 Perspectives d'Évolution Recommandées
1. **Intégration d'un SOAR (Security Orchestration, Automation and Response)** : Configurer le module Active Response de Wazuh pour déclencher des blocages dynamiques au niveau du pare-feu 
périmétrique dès la première alerte critique.
2. **Alimentation en Cyber Threat Intelligence (CTI)** : Interconnecter Graylog et Wazuh avec des plateformes comme MISP ou des flux AlienVault OTX afin de corréler les adresses IP 
avec des bases d'attaquants mondiales.
3. **Chiffrement Global mTLS** : Généraliser l'authentification mutuelle par certificats TLS sur l'intégralité des flux Rsyslog et Beats entre les machines clientes et le serveur SOC.
