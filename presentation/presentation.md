# PRÉSENTATION ORALE — SOC LAB INFRASTRUCTURE
## Déploiement et Démonstration Live d'un SOC Opérationnel

**Auteur :** Priscilla M. ([@priscillamania](https://github.com/priscillamania))  
**Société :** SecureNet Solutions  
**Formation :** BTS SIO / Licence Pro / BUT Informatique  

---

<!-- slide -->
# Slide 1 : Page de Titre
- **Titre :** Déploiement & Intégration d'une Infrastructure SOC
- **Sous-titre :** Wazuh, Graylog, Grafana et Scénarios d'Attaque Réseau
- **Intervenant :** Priscilla M.
- **Tuteur / Contexte :** SecureNet Solutions
- **Date :** Octobre 2026

---

<!-- slide -->
# Slide 2 : Contexte et Problématique 
- **Besoin Client (PME) :**
  - Manque de visibilité centralisée sur les événements de sécurité.
  - Nécessité de détecter les intrusions et les attaques en temps réel.
  - Conformité réglementaire et conservation des journaux d'audit.
- **Objectifs Techniques du Stage :**
  - Bâtir un laboratoire SOC complet sur 3 VMs Linux sécurisées.
  - Intégrer les briques leaders de l'Open Source : HIDS (Wazuh), SIEM/Log Management (Graylog), Visualisation (Grafana).
  - Simuler des attaques réalistes depuis un réseau hostile distinct pour éprouver la détection.

---

<!-- slide -->
# Slide 3 : Architecture de la Solution 
- **Topologie Réseau & Rôles des 3 VMs :**
  - **VM1 (192.168.10.10 - VMnet2) — Serveur SOC All-in-One :**
    - Wazuh Manager + Indexer + Dashboard (SIEM / HIDS)
    - Graylog 5.2 + OpenSearch + MongoDB (Centralisation des logs)
    - Grafana (Tableaux de bord d'exploitation)
  - **VM2 (192.168.20.20 - VMnet3) — Machine d'Attaque :**
    - Isole les outils offensifs (`nmap`, `hydra`, `nikto`) sur un sous-réseau externe.
  - **VM3 (192.168.10.30 & 192.168.20.30) — Machine Victime (Dual-Homed) :**
    - Serveur Web (Nginx) et SSH exposé.
    - Équipé de l'Agent Wazuh, de Filebeat et de Rsyslog pour transmettre la télémétrie vers VM1.

---

<!-- slide -->
# Slide 4 : Mesures de Sécurité Appliquées 
- **Les 7 piliers du Durcissement (Partie 1.2 — 15 pts) :**
  1. **SSH Durci :** Port 2222, clés asymétriques uniquement, interdiction du login root. *(Port 22 conservé sur VM3 pour la détection)*.
  2. **Pare-feu UFW :** Refus systématique par défaut (`default deny incoming`), ouverture ciblée par rôle.
  3. **Fail2Ban :** Bannissement automatique de 24h après 3 échecs consécutifs.
  4. **PAM pwquality :** Mots de passe $\ge 12$ caractères, complexité 4 classes.
  5. **Kernel sysctl :** Protection SYN cookies, anti-spoofing IP, randomisation ASLR.
  6. **Auditd :** Surveillance temps réel de `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`.
  7. **Hygiène Système :** Désactivation de `cups`, `avahi-daemon`, `bluetooth`.

---

<!-- slide -->
# Slide 5 : Démonstration Live Wazuh 
- **Points Clés démontrés en direct :**
  - Accès à l'interface Wazuh Dashboard (`http://192.168.10.10:5601`).
  - Statut de l'agent `soc-victim-vm3` : État **Active** et synchronisé.
  - Visualisation des événements de conformité et de l'inventaire système (SCA / FIM).
  - Démonstration de la réception des alertes d'intégrité en temps réel.

---

<!-- slide -->
# Slide 6 : Démonstration Live Graylog
- **Points Clés démontrés en direct :**
  - Connexion à Graylog Web (`http://192.168.10.10:9000`).
  - Validation du statut opérationnel des 3 entrées (Inputs) :
    - **Syslog UDP (514)** : Journaux noyau et système VM3.
    - **Beats TCP (5044)** : Journaux Nginx et auth.log via Filebeat.
    - **GELF UDP (12201)** : Prêt pour conteneurs applicatifs.
  - Recherche en direct des messages entrants avec le moteur OpenSearch.

---

<!-- slide -->
# Slide 7 : Démonstration Live Grafana
- **Présentation des 3 Tableaux de Bord Opérationnels :**
  - **Dashboard 1 (Vue générale des logs) :**
    - Métrique horaire des flux, Top 10 des sources, répartition par sévérité.
  - **Dashboard 2 (Alertes Sécurité Wazuh) :**
    - Jauge dynamique des alertes critiques ($\ge 7$), timeline temps réel des événements.
  - **Dashboard 3 (Surveillance SSH) :**
    - Graphique des échecs d'authentification par minute, cartographie des IPs attaquantes, règle d'alerte configurée (> 5 échecs/min).

---

<!-- slide -->
# Slide 8 : Scénario de Détection en Live
- **Exécution d'une Attaque Réelle en Direct :**
  - Lancement du Brute Force SSH depuis VM2 via Hydra :  
    `hydra -l root -P /opt/soc-lab/wordlists/passwd.txt ssh://192.168.20.30:22`
- **Résultats instantanés observés en direct :**
  1. **Fail2Ban :** L'adresse IP de l'attaquant VM2 est bannie après 3 tentatives.
  2. **Wazuh Dashboard :** Déclenchement de la règle critique **ID 5710** (Niveau 10).
  3. **Grafana :** Le Dashboard 3 affiche le pic de tentatives et passe l'alerte en rouge.
  4. **Graylog :** Les lignes d'échec d'authentification apparaissent instantanément.

---

<!-- slide -->
# Slide 9 : Difficultés Rencontrées et Solutions 
- **Conflit de ports sur VM1 :** Wazuh Indexer et OpenSearch convoitaient le port 9200.  
  $\rightarrow$ *Solution :* Isolation réseau d'OpenSearch dans Docker et mappage 9201.
- **Empreinte Mémoire RAM :** Risque de saturation avec l'ensemble des stacks sur une seule VM.  
  $\rightarrow$ *Solution :* Optimisation des options JVM heap (`-Xms1g -Xmx1g`) et `vm.max_map_count`.
- **Réseau Attaquant Séparé :** Nécessité d'isoler l'attaquant tout en assurant l'envoi des logs.  
  $\rightarrow$ *Solution :* Architecture VM3 en *Dual-Homed* (deux interfaces VMnet2 & VMnet3).

---

<!-- slide -->
# Slide 10 : Conclusion et Améliorations Possibles
- **Bilan :**
  - 100% des exigences fonctionnelles et sécuritaires atteintes.
  - Infrastructure résiliente, centralisée, documentée et prête pour la démonstration.
- **Pistes d'Évolution :**
  - Intégration d'un module SOAR (Active Response Wazuh pour blacklister les attaquants au niveau pare-feu).
  - Connexion de flux Cyber Threat Intelligence (CTI / MISP).
  - Déploiement de certificats TLS mutuels (mTLS) sur tous les flux de collecte.

---

# Questions & Réponses 
*Merci pour votre attention. Place aux échanges techniques.*
