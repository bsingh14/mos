#!/bin/bash

# 1. System Update and Docker Installation
# SUDO IS REQUIRED HERE: These are system-wide changes.
echo "Step 1: Installing Docker..."
sudo apt update && sudo apt upgrade -y
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 2. Create Directory Structure
# NO SUDO NEEDED: Creating folders in your home directory (~/) 
# is permitted for your standard user.
echo "Step 2: Creating IIoT-Stack directories..."
mkdir -p ~/iiot-stack/config ~/iiot-stack/data ~/iiot-stack/log \
         ~/iiot-stack/influxdb_data ~/iiot-stack/telegraf_config

# change ownership to $USER
sudo chown -R $USER:$USER ~/iiot-stack

cd ~/iiot-stack

# 3. Create mosquitto.conf
# NO SUDO NEEDED: You own the folder now.
echo "Step 3: Generating mosquitto.conf...: moved to another script"
cat <<EOF > config/mosquitto.conf
# --- Global / Persistence ---
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

# --- Port 1883: Internal Factory Traffic (Telegraf) ---
listener 1883 0.0.0.0
allow_anonymous false
password_file /mosquitto/config/password.txt

# --- Port 8883: External Secure Traffic (IoT Devices) ---
#listener 8883 0.0.0.0
#cafile /mosquitto/config/certs/ca.crt
#certfile /mosquitto/config/certs/server.crt
#keyfile /mosquitto/config/certs/server.key
#require_certificate true
#use_identity_as_username true
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
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: "my-super-secret-admin-token-123"

  telegraf:
    image: telegraf:latest
    container_name: telegraf
    restart: always
    volumes: ["./telegraf_config:/etc/telegraf"]
    depends_on: ["mqtt-broker", "influxdb"]
EOF

# 5. Create telegraf.conf
echo "Step 5: Generating telegraf.conf..."
cat <<EOF > telegraf_config/telegraf.conf
[agent]
  interval = "10s"
  flush_interval = "10s"
  hostname = ""
  omit_hostname = false

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "my-super-secret-admin-token-123"
  organization = "SmallScaleIndustry"
  bucket = "FactoryData"

[[inputs.mqtt_consumer]]
  servers = ["tcp://mosquitto:1883"]
  topics = ["factory/#"]
  username = "factory_admin"
  password = "asbhatti"
  data_format = "json"
EOF

# 6. Generate Mosquitto Password File
echo "Initializing Log File..."
touch ~/iiot-stack/log/mosquitto.log
touch ~/iiot-stack/config/password.txt
sudo chown 1883:1883 ~/iiot-stack/log/mosquitto.log
sudo chmod 666 ~/iiot-stack/log/mosquitto.log
sudo chmod 666 ~/iiot-stack/config/password.txt
# Hand over data and log folders to the Mosquitto container user
sudo chown -R 1883:1883 ~/iiot-stack/data ~/iiot-stack/log

echo "Step 6: Setting up Mosquitto password..."
# Using sudo one last time here ensures that even if Docker 
# messed up permissions earlier, the command will succeed.

sudo chown -R $USER:$USER ~/iiot-stack/config

sg docker -c "docker run --rm -v ~/iiot-stack/config:/mosquitto/config eclipse-mosquitto \
mosquitto_passwd -b -c /mosquitto/config/password.txt factory_admin asbhatti"

if [ -f ~/iiot-stack/config/password.txt ]; then
    echo "SUCCESS: password.txt created."
else
    echo "ERROR: password.txt was not created."
fi

# enusre config folder is accessible by $USER
sudo chown -R $USER:$USER ~/iiot-stack/config

# 7. Final Instructions
echo "-------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "-------------------------------------------------------"
# The 'exec' command here is the secret to avoiding a logout.
# It restarts the shell with the new group permissions.
#exec newgrp docker <<EONG
#  cd ~/iiot-stack
#  docker compose up -d
#  echo "Stack started successfully!"
#  echo "Access InfluxDB at http://$(hostname -I | awk '{print $1}'):8086"
#EONG
