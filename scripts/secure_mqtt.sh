#!/bin/bash

# Define variables
STACK_DIR="$HOME/iiot-stack"
CERT_DIR="$STACK_DIR/config/certs"
RPI_IP=$(hostname -I | awk '{print $1}')

echo "--- Step 1: Creating Certificate Directory ---"
sudo mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "--- Step 2: Generating Certificate Authority (CA) ---"
sudo openssl req -new -x509 -days 3650 -extensions v3_ca \
    -keyout ca.key -out ca.crt -nodes \
    -subj "/CN=MyIIoT-CA"

echo "--- Step 3: Creating OpenSSL Config for IP Support (SAN) ---"
# This fixes the "Hostname/IP does not match" error in MQTT Explorer
cat <<EOF | sudo tee openssl.cnf
[v3_req]
subjectAltName = IP:$RPI_IP
EOF

echo "--- Step 4: Generating Server Certificate for $RPI_IP ---"
sudo openssl genrsa -out server.key 2048
sudo openssl req -new -out server.csr -key server.key -subj "/CN=$RPI_IP"
sudo openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 3650 -extensions v3_req -extfile openssl.cnf

echo "--- Step 5: Setting Permissions ---"
# Ensure the Mosquitto container can read the certificates
sudo chmod -R 755 "$CERT_DIR"

echo "--- Step 6: Updating mosquitto.conf ---"
cat <<EOF | sudo tee "$STACK_DIR/config/mosquitto.conf"
# Internal Docker network listener
listener 1883 0.0.0.0

# Secure external listener
listener 8883 0.0.0.0
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key

allow_anonymous false
password_file /mosquitto/config/password.txt
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

echo "--- Step 7: Updating docker-compose.yml ---"
cat <<EOF | sudo tee "$STACK_DIR/docker-compose.yml"
services:
  mqtt-broker:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    restart: always
    ports:
      - "1883:1883"
      - "8883:8883"
    volumes:
      - ./config:/mosquitto/config
      - ./data:/mosquitto/data
      - ./log:/mosquitto/log

  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    restart: always
    ports: ["8086:8086"]
    volumes: ["./influxdb_data:/var/lib/influxdb2"]
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: "mos"
      DOCKER_INFLUXDB_INIT_PASSWORD: "asbhatti"
      DOCKER_INFLUXDB_INIT_ORG: "SmallScaleIndustry"
      DOCKER_INFLUXDB_INIT_BUCKET: "FactoryData"
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: "my-super-secret-admin-token-123"

  telegraf:
    image: telegraf:latest
    container_name: telegraf
    restart: always
    volumes: ["./telegraf_config:/etc/telegraf"]
    depends_on: ["mqtt-broker", "influxdb"]
EOF

echo "--- Step 8: Restarting the Stack ---"
cd "$STACK_DIR"
docker compose up -d
docker compose restart mqtt-broker

echo "-------------------------------------------------------"
echo "HARDENING COMPLETE!"
echo "Broker IP: $RPI_IP"
echo "Secure Port: 8883"
echo "Download $CERT_DIR/ca.crt to your PC for MQTT Explorer."
echo "-------------------------------------------------------"
