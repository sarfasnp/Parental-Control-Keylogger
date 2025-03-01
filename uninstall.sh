#!/bin/bash

echo "[*] Stopping keylogger service..."
sudo systemctl stop keylogger.service
sudo systemctl disable keylogger.service
sudo rm /etc/systemd/system/keylogger.service

echo "[*] Removing keylogger files..."
sudo rm /usr/local/bin/keylogger.py

echo "[*] Uninstallation complete."

