#!/bin/bash
echo "[INFO] Installing and configuring UFW firewall"
apt-get update
apt-get install -y ufw

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
