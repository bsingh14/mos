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
openssl req -new -x509 -days 3650 -extensions v3_ca \
    -keyout ca.key -out ca.crt -nodes \
    -subj "/CN=MyIIoT-CA"

echo "--- Step 3: Creating OpenSSL Config ---"
cat <<EOF > openssl.cnf
[v3_req]
subjectAltName = IP:$RPI_IP
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
listener 1883 0.0.0.0
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
cat <<EOF | sudo tee "$STACK_DIR/docker-compose.yml" > /dev/null
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

#echo "--- Step 8: Restarting the Stack ---"
#cd "$STACK_DIR"
# Use sudo for docker commands to bypass the 'socket permission' error
#sudo docker compose up -d
#sudo docker compose restart mqtt-broker
