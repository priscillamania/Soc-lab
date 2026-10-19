#!/bin/bash
# Hardening spécifique VM3 (Agent)

source ./hardening-common.sh

# Ports pour l'agent et Nginx
ufw allow 80/tcp
ufw allow 1514/tcp
ufw reload

