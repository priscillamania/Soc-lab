#!/bin/bash
# ==============================================================================
# SOC Lab — Scénario B : Modification d'un fichier critique (Partie 3.2 - 5 pts)
# À exécuter SUR la VM3 (Victime)
# Utilisation : sudo bash scripts/scenario-b-auditd.sh
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Erreur : Ce script doit être exécuté avec les privilèges root (sudo)."
    exit 1
fi

echo "================================================================="
echo " [SCÉNARIO B] Simulation de modification d'un fichier critique"
echo " Cible : /etc/passwd surveillé par Auditd"
echo " Commande officielle : echo \"test\" >> /etc/passwd"
echo "================================================================="

# Sauvegarde préalable de précaution
cp /etc/passwd /etc/passwd.soc_backup

echo "[*] Injection d'une ligne dans /etc/passwd..."
echo "soc_test_user:x:1999:1999:SOC Audit Test:/home/soc_test_user:/bin/false" >> /etc/passwd

echo "[*] Vérification de l'alerte locale Auditd..."
ausearch -k fichier_critique --recent || true

echo ""
echo "================================================================="
echo " [✓] Événement d'altération généré !"
echo " Résultats attendus à vérifier :"
echo " 1. Wazuh -> Alerte d'intégrité / syscheck (rule.id: 550, level >= 7)"
echo " 2. Wazuh Dashboard -> Alerte visible dans Security Events"
echo " 3. Grafana Dashboard 2 -> Alerte comptabilisée dans les niveaux critiques"
echo "================================================================="
echo ""
echo "[*] Pour restaurer le fichier original après le test :"
echo "    sudo cp /etc/passwd.soc_backup /etc/passwd"
