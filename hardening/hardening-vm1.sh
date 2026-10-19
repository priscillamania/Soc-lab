#!/bin/bash
# Hardening spécifique VM1 (Wazuh Server)

source ./hardening-common.sh

# Ports Wazuh + Grafana + Prometheus
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 9090/tcp
ufw allow 9100/tcp
ufw allow 9200/tcp
ufw allow 55000/tcp
ufw allow 1514/tcp
ufw reload
