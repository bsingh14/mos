#!/bin/bash

# Define paths
STACK_DIR="$HOME/iiot-stack"
CERT_DIR="$STACK_DIR/config/certs"
CLIENT_NAME="FactoryDevice01"

echo "--- Step 1: Entering Certificate Directory ---"
cd "$CERT_DIR" || { echo "Error: Cert directory not found. Run previous script first."; exit 1; }

echo "--- Step 2: Generating Client Key and Certificate ($CLIENT_NAME) ---"
# 1. Create a Private Key for the Client
sudo openssl genrsa -out client.key 2048

# 2. Create a CSR (Common Name will be the MQTT Username)
sudo openssl req -new -out client.csr -key client.key -subj "/CN=$CLIENT_NAME"

# 3. Sign the Client CSR with your existing CA
sudo openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -days 365

echo "--- Step 3: Updating mosquitto.conf for mTLS ---"
cat <<EOF | sudo tee "$STACK_DIR/config/mosquitto.conf"
# Internal Docker network listener
listener 1883 0.0.0.0

# Secure external listener (mTLS)
listener 8883 0.0.0.0
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key

# Authentication Settings
require_certificate true
use_identity_as_username true
allow_anonymous false

# Persistence and Logs
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

echo "--- Step 4: Fixing Permissions for SCP and Docker ---"
# Set ownership to current user so you can SCP files out
sudo chown -R $USER:$USER "$CERT_DIR"
# Ensure directory remains accessible to Mosquitto container
chmod 755 "$CERT_DIR"
chmod 644 "$CERT_DIR/client.crt"
chmod 600 "$CERT_DIR/client.key"

echo "--- Step 5: Restarting Mosquitto ---"
cd "$STACK_DIR"
docker compose restart mqtt-broker

echo "-------------------------------------------------------"
echo "mTLS SETUP COMPLETE!"
echo "-------------------------------------------------------"
echo "1. Client Username is now: $CLIENT_NAME"
echo "2. Download these 3 files to your PC for MQTT Explorer:"
echo "   - $CERT_DIR/ca.crt"
echo "   - $CERT_DIR/client.crt"
echo "   - $CERT_DIR/client.key"
echo "-------------------------------------------------------"
