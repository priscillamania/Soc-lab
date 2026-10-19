'''
# SOC Lab — Déploiement & Intégration (Architecture Native) 

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu)
![Wazuh](https://img.shields.io/badge/Wazuh-4.14.8-005571)
![Graylog](https://img.shields.io/badge/Graylog-5.2-FF3633)
![Grafana](https://img.shields.io/badge/Grafana-11.x-F46800?logo=grafana)
![Prometheus](https://img.shields.io/badge/Prometheus-2.x-E6522C?logo=prometheus)

##  Description


Infrastructure d'un Security Operations Center (SOC) complète, avec :
- **Wazuh** : SIEM + HIDS (détection d'intrusion)
- **Graylog** : centralisation des logs
- **Prometheus** : supervision d'infrastructure
- **Grafana** : visualisation et dashboards

##  Architecture

        ┌────────────────────────────────────────┐
        │        VM2 — Machine Attaquant         │
        │             192.168.20.20              │
        │          (Hydra, Nmap, Kali)           │
        └───────────────────┬────────────────────┘
                            │
              Réseau Attaque│ (VMnet3 : 192.168.20.0/24)
                            ▼
        ┌────────────────────────────────────────┐
        │          VM3 — Machine Cible           │
        │   ens34 (Externe) : 192.168.20.30      │
        │   ens33 (Interne) : 192.168.10.30      │
        │    (Nginx, SSH:22/2222, Sondes SOC)    │
        └───────────────────┬────────────────────┘
                            │
                 Réseau SOC │ (VMnet2 : 192.168.10.0/24)
                            ▼
        ┌─────────────────────────────────────────┐
        │          VM1 — Serveur SOC Unifié       │
        │              192.168.10.10              │
        │   ┌──────────────────────────────────┐  │
        │   │ Wazuh Manage + Indexer Opensearch│  │
        │   │+ Grafana + Prometheus + Dashboard│  │ 
        │   └──────────────────────────────────┘  │
        └─────────────────────────────────────────┘
 
|    VM   |       IP     | Services |
|----|----|--------------|
| **VM1** | 192.168.1.54 | Wazuh Manager, Wazuh Indexer (OpenSearch), Wazuh Dashboard, Grafana, Prometheus |
| **VM2** | 192.168.1.20 | Machine d'attaque (Hydra, Nmap) |
| **VM3** | 192.168.1.26 | Agent Wazuh, Filebeat, Nginx, auditd |

##  Note sur l'implémentation

Pour des raisons de **stabilité et de performance**, les services (Wazuh, Grafana, Prometheus) ont été installés **en natif via APT** (sans Docker). L'Indexer natif de Wazuh (basé sur OpenSearch) est utilisé pour le stockage et la recherche des logs, remplaçant ainsi Graylog.

##  Instructions de déploiement

1. **Configuration réseau et hôtes**
# Configuration Réseau

Les VMs utilisent des IPs statiques dans le réseau `192.168.1.0/24`.

	- VM1 : 192.168.1.54
	- VM2 : 192.168.1.20
	- VM3 : 192.168.1.26

Les noms d'hôtes sont définis dans `/etc/hosts` :
	- `vm1.soc-lab.local`
	- `vm2.soc-lab.local`
	- `vm3.soc-lab.local`
   - Copier les fichiers de `config/hosts/` vers `/etc/hosts` sur chaque VM.
   - Appliquer les configurations Netplan (`config/network/`).

2. **Déploiement de la VM1 (Serveur SOC)**
   sudo bash scripts/script-deploiement-vm1.sh

3. **Déploiement de la VM3 (Cible)
   sudo bash scripts/script-deploiement-vm3.sh

4. **Durcissement (Hardening) des 3 VMs
   sudo bash hardening/hardening-common.sh
   sudo bash hardening/hardening-vm1.sh
   sudo bash hardening/hardening-vm2.sh
   sudo bash hardening/hardening-vm3.sh
