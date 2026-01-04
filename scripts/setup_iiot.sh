#!/bin/bash

# 1. System Update and Docker Installation
echo "Step 1: Installing Docker..."
sudo apt update && sudo apt upgrade -y
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 2. Create Directory Structure
echo "Step 2: Creating IIoT-Stack directories..."
mkdir -p ~/iiot-stack/config ~/iiot-stack/data ~/iiot-stack/log \
         ~/iiot-stack/influxdb_data ~/iiot-stack/telegraf_config

cd ~/iiot-stack

# 3. Create mosquitto.conf
echo "Step 3: Generating mosquitto.conf..."
cat <<EOF > config/mosquitto.conf
listener 1883 0.0.0.0
allow_anonymous false
password_file /mosquitto/config/password.txt
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

# 4. Create docker-compose.yml
echo "Step 4: Generating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  mqtt-broker:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    restart: always
    ports: ["1883:1883"]
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

  telegraf:
    image: telegraf:latest
    container_name: telegraf
    restart: always
    volumes: ["./telegraf_config:/etc/telegraf"]
    depends_on: ["mqtt-broker", "influxdb"]
EOF

# 5. Generate Mosquitto Password File
echo "Step 5: Setting up Mosquitto password..."
# We use the -b flag to pass the password directly in the command for automation
docker run --rm -v ~/iiot-stack/config:/mosquitto/config eclipse-mosquitto \
mosquitto_passwd -b -c /mosquitto/config/password.txt factory_admin asbhatti

# 6. Final Instructions
echo "-------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "-------------------------------------------------------"
echo "IMPORTANT: Run 'newgrp docker' or log out/in before starting containers."
echo "Then run:"
echo "cd ~/iiot-stack && docker compose up -d"
echo "-------------------------------------------------------"
