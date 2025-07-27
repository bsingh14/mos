
# 🛰️ Mosquitto MQTT Broker Setup on a Linux VPS (with SSL)

This guide helps you install, configure, and secure the [Eclipse Mosquitto](https://mosquitto.org/) MQTT broker on a Linux VPS, with support for authentication and optional SSL encryption.

---

## 📦 Step 1: Install Mosquitto and Clients

```bash
sudo apt update
sudo apt install mosquitto mosquitto-clients -y
```

---

## ⚙️ Step 2: Configure Mosquitto for Remote Access

Create a configuration file:

```bash
sudo nano /etc/mosquitto/conf.d/remote.conf
```

Add the following:

```conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

---

## 👤 Step 3: Create MQTT User and Password

```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd your_username
```

---

## 🚀 Step 4: Start and Enable Mosquitto Service

```bash
sudo systemctl restart mosquitto
sudo systemctl enable mosquitto
```

---

## 🔓 Step 5: Open Firewall Port (1883 for MQTT)

If using UFW:

```bash
sudo ufw allow 1883
```

Or, allow port 1883 from your VPS provider's security group settings (e.g., AWS EC2, Google Cloud, etc.)

---

## 🧪 Step 6: Test the MQTT Broker (from remote machine)

### Subscriber:

```bash
mosquitto_sub -h your_vps_ip -t test/topic -u your_username -P your_password
```

### Publisher:

```bash
mosquitto_pub -h your_vps_ip -t test/topic -m "Hello MQTT from VPS" -u your_username -P your_password
```

---

## 🔒 Step 7: Add SSL Support (Optional but Recommended)

### 7.1 Install Certbot and Get SSL Certificate

If you have a domain pointing to your VPS:

```bash
sudo apt install certbot -y
sudo certbot certonly --standalone -d mqtt.yourdomain.com
```

Certificates will be stored in:

```
/etc/letsencrypt/live/mqtt.yourdomain.com/
```

---

### 7.2 Configure Mosquitto with SSL

Create file:

```bash
sudo nano /etc/mosquitto/conf.d/ssl.conf
```

Add the following:

```conf
listener 8883
cafile /etc/letsencrypt/live/mqtt.yourdomain.com/chain.pem
certfile /etc/letsencrypt/live/mqtt.yourdomain.com/cert.pem
keyfile /etc/letsencrypt/live/mqtt.yourdomain.com/privkey.pem

require_certificate false
allow_anonymous false
password_file /etc/mosquitto/passwd
```

Restart Mosquitto:

```bash
sudo systemctl restart mosquitto
```

---

### 7.3 Test SSL MQTT Connection

Use MQTT client that supports SSL:

```bash
mosquitto_pub -h mqtt.yourdomain.com -p 8883 --capath /etc/ssl/certs \
 -t test/topic -m "Hello with SSL" -u your_username -P your_password
```

---

## 🌐 Optional: WebSocket Support (Port 9001)

Edit (or create):

```bash
sudo nano /etc/mosquitto/conf.d/websocket.conf
```

Add:

```conf
listener 9001
protocol websockets
password_file /etc/mosquitto/passwd
```

Restart:

```bash
sudo systemctl restart mosquitto
```

---

## 🧼 Logs and Troubleshooting

Logs are typically stored in:

```
/var/log/mosquitto/mosquitto.log
```

You can also check service status:

```bash
sudo systemctl status mosquitto
```

---

## ✅ Done!

Your secure MQTT broker is now ready to use from anywhere!

---

## 🔐 Tips for Production
- Use firewall rules to restrict access to trusted IPs.
- Set up automatic SSL renewal: `sudo crontab -e`  
  ```cron
  0 3 * * * certbot renew --quiet && systemctl restart mosquitto
  ```
- Consider using MQTT over WebSockets for browser-based clients.
- Monitor usage with tools like Telegraf + InfluxDB + Grafana.

---
