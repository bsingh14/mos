# IoT Stack on Raspberry Pi — Setup Checklist

This README provides a **step-by-step checklist** to set up a complete IoT stack on Raspberry Pi with:

- MQTT Broker (Mosquitto)
- Time-series Database (InfluxDB v2)
- Flow-based automation (Node-RED)
- Dashboards (Grafana)

Everything runs **free** and on a single Raspberry Pi using **Docker Compose**.

---

## ✅ Setup Checklist

### 1. Raspberry Pi Preparation
- [x] Raspberry Pi 4 with 2GB+ RAM (Pi 3 works but slower)
- [x] Install Raspberry Pi OS (64-bit preferred)
- [x] SSH enabled & user with `sudo`

### 2. Install Docker & Compose
- [x] Install Docker  
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  ```
- [x] Reboot Pi or re-login
- [x] Install Docker Compose plugin  
  ```bash
  sudo apt update
  sudo apt install -y docker-compose-plugin
  ```

### 3. Project Folder Structure
- [x] Create base folder
  ```bash
  mkdir -p ~/iot-stack/{mosquitto/config,mosquitto/data,mosquitto/log,influxdb,node-red,grafana}
  cd ~/iot-stack
  ```

### 4. Configuration Files
- [x] Create `docker-compose.yml` in `~/iot-stack`
- [x] Create `mosquitto.conf` in `~/iot-stack/mosquitto/config/`

### 5. Start the Stack
- [x] Run containers  
  ```bash
  docker compose up -d
  ```
- [x] Verify services are running  
  ```bash
  docker ps
  ```

### 6. InfluxDB Setup
- [x] Access InfluxDB at `http://<rpi-ip>:8086`
- [x] Login with `admin` / `YourInfluxAdminPass`
- [ ] Note down **API Token**

### 7. Node-RED Setup
- [x] Access Node-RED at `http://<rpi-ip>:1880`
- [x] Install palettes:
  - [x] `node-red-dashboard`
  - [x] `node-red-contrib-influxdb-v2`
- [ ] Create flow: MQTT → Parse → InfluxDB
- [ ] Test with sample MQTT publish:
  ```bash
  mosquitto_pub -h <rpi-ip> -t "tenant/tenant1/device/device123/telemetry" -m '{"temp":23.5,"hum":55}'
  ```

### 8. Grafana Setup
- [ ] Access Grafana at `http://<rpi-ip>:3000`
- [ ] Login with `admin` / `admin` (change password immediately)
- [ ] Add InfluxDB data source
- [ ] Create dashboards (per tenant/device)

### 9. Security (LAN now, Public later)
- [ ] Set Mosquitto password file
- [ ] Disable anonymous access
- [ ] Secure Node-RED and Grafana with strong passwords
- [ ] (Later) Enable TLS for public access

### 10. Data Management
- [ ] Verify InfluxDB bucket retention (default 30d)
- [ ] Set backup strategy
- [ ] Plan long-term storage (aggregation or export)

---

## 🔑 Quick Access URLs
- Mosquitto MQTT: `mqtt://<rpi-ip>:1883`
- Node-RED: `http://<rpi-ip>:1880`
- InfluxDB: `http://<rpi-ip>:8086`
- Grafana: `http://<rpi-ip>:3000`

---

## 🚀 Next Steps
- Add new flows in Node-RED for custom logic
- Share dashboards with customers using Grafana view-only accounts
- Prepare migration path if scaling beyond one Raspberry Pi
