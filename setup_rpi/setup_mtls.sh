#!/bin/bash

# Define paths
STACK_DIR="$HOME/iiot-stack"
CERT_DIR="$STACK_DIR/config/certs"
CLIENT_NAME="FactoryDevice01"

echo "--- Step 1: Entering Certificate Directory ---"
# Ensure we own the directory before starting
sudo chown -R $USER:$USER "$CERT_DIR"
cd "$CERT_DIR" || { echo "Error: Cert directory not found."; exit 1; }

echo "--- Step 2: Generating Client Key and Certificate ($CLIENT_NAME) ---"
# Removed sudo: standard user can generate these
openssl genrsa -out client.key 2048
openssl req -new -out client.csr -key client.key -subj "/CN=$CLIENT_NAME"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -days 365

echo "--- Step 3: Updating mosquitto.conf for mTLS ---"
# We use simple redirection because we confirmed ownership in Step 1
cat <<EOF > "$STACK_DIR/config/mosquitto.conf"
# Persistence and Logs
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

# Internal Listener (For Telegraf/Internal Apps)
listener 1883 0.0.0.0
allow_anonymous false
password_file /mosquitto/config/password.txt

# Secure External Listener (mTLS for Devices)
listener 8883 0.0.0.0
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key
require_certificate true
use_identity_as_username true
EOF

echo "--- Step 4: Finalizing Permissions for Mosquitto and SCP ---"
# 1. Give the files to the user so SCP works easily
chown $USER:$USER client.key client.crt client.csr
# 2. Set restrictive permissions for the private key (Standard Security Practice)
chmod 600 client.key
chmod 644 client.crt

# 3. Hand back ownership of the certs folder to the Mosquitto container user
# This is crucial so the container can read the keys on restart
sudo chown -R 1883:1883 "$CERT_DIR"

#echo "--- Step 5: Restarting Mosquitto ---"
#cd "$STACK_DIR"
#docker compose restart mqtt-broker

echo "-------------------------------------------------------"
echo "mTLS SETUP COMPLETE!"
echo "-------------------------------------------------------"
