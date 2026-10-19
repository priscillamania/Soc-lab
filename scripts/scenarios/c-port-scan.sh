#!/bin/bash
# ==============================================================================
# SOC Lab — Scénario C : Scan de ports Nmap (Partie 3.3 - 5 pts)
# À exécuter depuis la VM2 (Attaquant) contre la VM3 (Victime)
# Utilisation : bash scripts/attack-scenario-c-nmap.sh [IP_CIBLE]
# ==============================================================================

set -e

TARGET_IP="${1:-192.168.10.30}"

sudo nmap -sS -p- -T4 -v "${TARGET_IP}"

echo ""
echo " [✓] Scan de ports terminé !"
echo " Résultats attendus à vérifier les logs Nginx et les alertes Wazuh:"
