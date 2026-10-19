# Architecture Réseau — SOC Lab (Nouvelle Architecture Révisée)

## 1. Contexte du Changement (Consigne Verbale)
- **VM1 (SOC Server)** : Regroupe désormais toute l'infrastructure de détection et centralisation (Wazuh, Graylog, OpenSearch, MongoDB, Grafana) sur le réseau interne **VMnet2** (`192.168.10.0/24`).
- **VM2 (Machine Attaquant)** : Dédiez à la simulation d'attaques (Nmap, Hydra) sur un réseau séparé **VMnet3** (`192.168.20.0/24`).
- **VM3 (Machine Victime)** : Héberge l'Agent Wazuh, Filebeat, Rsyslog, et le serveur Web Nginx.

---

## 2. Topologie Recommandée : Machine Victime Dual-Homed (DMZ)

```
[ VM2 - Attaquant ] (192.168.20.20)
       │
       │ (Réseau VMnet3 : 192.168.20.0/24)
       ▼
[ VM3 - Victime (ens34 : 192.168.20.30) ]
[ VM3 - Victime (ens33 : 192.168.10.30) ]
       │
       │ (Réseau VMnet2 : 192.168.10.0/24 - Isolé)
       ▼
[ VM1 - SOC Server ] (192.168.10.10)
  ├── Wazuh Manager & Indexer & Dashboard
  ├── Graylog & OpenSearch & MongoDB
  └── Grafana
```

### Avantages de cette topologie :
1. **Sécurité et Réalisme SOC** : Le serveur de supervision (VM1) n'est jamais joignable directement par l'attaquant (VM2).
2. **Visibilité Complète** : La machine cible (VM3) subit les attaques sur son interface externe (`ens34`) et transfère immédiatement toute la télémétrie vers VM1 par son interface interne (`ens33`).
3. **Zéro perturbation des flux** : Aucun risque de conflit IP ou de coupure de service.

---

## 3. Configuration Hyperviseur (VMware Workstation / VirtualBox)

### Dans VMware Workstation :
1. **VMnet2 (Host-only ou LAN Segment)** : Plage `192.168.10.0/24`
   - Attribuer à la carte réseau de **VM1** (`ens33`).
   - Attribuer à la première carte de **VM3** (`ens33`).
2. **VMnet3 (Host-only ou LAN Segment)** : Plage `192.168.20.0/24`
   - Attribuer à la carte réseau de **VM2** (`ens33`).
   - Attribuer à la seconde carte de **VM3** (`ens34`).

### Dans VirtualBox :
- Réseau Interne 1 nommé `soc-internal` (`192.168.10.0/24`) pour VM1 et VM3 (Adapter 1).
- Réseau Interne 2 nommé `soc-external` (`192.168.20.0/24`) pour VM2 et VM3 (Adapter 2).

---

## 4. Application sur les machines

1. **Sur VM1** :
   ```bash
   sudo cp config/network/01-netplan-vm1.yaml /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ```
2. **Sur VM2** :
   ```bash
   sudo cp config/network/01-netplan-vm2.yaml /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ```
3. **Sur VM3** :
   ```bash
   sudo cp config/network/01-netplan-vm3-dual-nic.yaml /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ```
