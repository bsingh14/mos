## download and install 64-bit OS(recommended) on Model 4
### Update and Install Docker
```
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io -y
sudo systemctl enable --now docker
# Add your current user to the docker group (so you don't need 'sudo' for docker commands)
sudo usermod -aG docker $USER
Reboot or start new ssh session
```
### If `sudo systemctl enable --now docker` fails then
```
# First, remove any broken fragments of the previous installation:
sudo apt-get purge docker.io -y
sudo apt-get autoremove -y

# Run this single command to download and execute the official installer. This script is recommended for Raspberry Pi as it correctly identifies the ARM64 architecture.
curl -sSL https://get.docker.com | sh

# Now that the official script has created the necessary unit files, start the service. If it still fails here, run sudo reboot and try this step again.
sudo systemctl enable --now docker

# Add your user to the docker group so you can run containers without `sudo`.
sudo usermod -aG docker $USER
# Refresh your session without logging out
newgrp docker 

# Reboot or start new ssh session, Check if the service is active and the unit exists
sudo systemctl status docker
```

### Setting up MQTT broker
- Run these commands to create persistent storage for your configuration and data
`mkdir -p ~/mosquitto/config ~/mosquitto/data ~/mosquitto/log`

- Since Mosquitto 2.0+ is "secure by default," you must create a config file to allow external devices (like your ESP32) to connect.
`nano ~/mosquitto/config/mosquitto.conf`
- Paste this exact text into the file:
```
# Listen on port 1883 for all network interfaces
listener 1883 0.0.0.0

# Security: Disable anonymous access
allow_anonymous false
password_file /mosquitto/config/password.txt

# Persistence: Keep data after a restart
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
```
- You need to create the password.txt file and add a user (e.g., factory_admin).
```
# This command runs a temporary container just to generate the password file, it will ask you to enter a password twice. Note it down; your ESP32 will need it.
docker run --rm -it -v ~/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -c /mosquitto/config/password.txt factory_admin
```
- This command starts the broker and ensures it auto-restarts if the Pi ever loses power.
```
docker run -d \
  --name mosquitto \
  --restart always \
  -p 1883:1883 \
  -v ~/mosquitto/config:/mosquitto/config \
  -v ~/mosquitto/data:/mosquitto/data \
  -v ~/mosquitto/log:/mosquitto/log \
  eclipse-mosquitto
```
- Check if the container is running: `docker ps`. You should see a container named mosquitto with the status Up.
- You will need this to point your ESP32 to the broker: `hostname -I`. Look for the first IP, usually something like 192.168.x.x
- How to test it right now (No hardware needed):
  - If you have a computer on the same Wi-Fi, download MQTT Explorer.
  - Host: Your Pi's IP
  - Port: 1883
  - Username: factory_admin
  - Password: (The one you just set)
### Testing the setup:
- start listening on RPI `docker exec -it mosquitto mosquitto_sub -h localhost -t "factory/motor1/vibration" -u factory_admin -P "password"`
- use the explorer to publish data.
- Or install the client
```
sudo apt install mosquitto-clients -y
mosquitto_sub -h localhost -t "factory/motor1/vibration" -u factory_admin -P "password"
```
