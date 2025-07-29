#!/bin/bash
echo "[INFO] Installing and configuring SSH server"
apt-get update
apt-get install -y openssh-server
systemctl enable ssh
systemctl start ssh
