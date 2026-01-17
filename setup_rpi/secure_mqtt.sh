#!/bin/bash

# Define variables
STACK_DIR="$HOME/iiot-stack"
CERT_DIR="$STACK_DIR/config/certs"
RPI_IP=$(hostname -I | awk '{print $1}')

echo "--- Step 1: Force Reclaiming Directory Ownership ---"
# We use sudo for the mkdir and chown to override Docker's root ownership
sudo mkdir -p "$CERT_DIR"
sudo chown -R $USER:$USER "$STACK_DIR"
cd "$CERT_DIR" || exit

echo "--- Step 2: Generating Certificate Authority (CA) ---"
openssl req -new -x509 -days 3650 -nodes -out ca.crt -keyout ca.key -subj "/CN=MyIIoT-CA"
chmod 644 ca.crt

echo "--- Step 3: Creating OpenSSL Config ---"
cat <<EOF > openssl.cnf
[v3_req]
subjectAltName = IP:$RPI_IP,DNS:mosquitto
EOF

echo "--- Step 4: Generating Server Certificate ---"
openssl genrsa -out server.key 2048
openssl req -new -out server.csr -key server.key -subj "/CN=$RPI_IP"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 3650 -extensions v3_req -extfile openssl.cnf

echo "--- Step 5: Setting Permissions for Mosquitto ---"
sudo chmod 644 ca.crt server.crt
sudo chmod 600 ca.key server.key
# Handing ownership to the Mosquitto user ID (1883)
sudo chown -R 1883:1883 "$CERT_DIR"

echo "--- Step 6: Updating mosquitto.conf ---"
# Using sudo tee because the folder is now owned by 1883
cat <<EOF | sudo tee "$STACK_DIR/config/mosquitto.conf" > /dev/null
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

listener 1883 0.0.0.0
allow_anonymous false
password_file /mosquitto/config/password.txt

listener 8883 0.0.0.0
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key
require_certificate true
use_identity_as_username true
EOF
