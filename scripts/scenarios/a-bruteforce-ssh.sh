#!/bin/bash
# Scénario A : Brute Force SSH (à exécuter sur VM2)

for i in $(seq 1 15); do
  ssh root@192.168.10.20 -p 22 -o ConnectTimeout=2 2>/dev/null
done
echo "[+] Attaque terminée. Vérifiez les alertes Wazuh (rule.id 5710)."
