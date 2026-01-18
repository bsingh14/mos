# ESP32-S3 MQTT LED Demo

This project demonstrates controlling an onboard WS2812 RGB LED on the ESP32-S3-DevKitC-1 via MQTT commands. You can turn the LED **OFF, RED, GREEN, or BLUE** using an MQTT broker.

---

## Table of Contents

- [Requirements](#requirements)  
- [Hardware Setup](#hardware-setup)  
- [Software Setup](#software-setup)  
  - [Install ESP-IDF](#install-esp-idf)  
  - [Clone Project](#clone-project)  
  - [Add LED Strip Component](#add-led-strip-component)  
  - [Configure Wi-Fi & MQTT](#configure-wifi--mqtt)  
- [Build & Flash](#build--flash)  
- [MQTT Usage](#mqtt-usage)  
- [Troubleshooting](#troubleshooting)  

---

## Requirements

- **ESP32-S3-DevKitC-1 v1.0**  
- **Addressable RGB LED** (onboard or external WS2812)  
- **MQTT Broker** (e.g., Mosquitto)  
- **ESP-IDF v5.4.1** installed on your system  
- Python 3.8+ (for ESP-IDF tools)

---

## Hardware Setup

- Onboard LED pin for ESP32-S3-DevKitC-1: **GPIO48**  
- If using an external WS2812 LED:
  - Connect **Data IN** to GPIO48  
  - Connect **VCC** to 3.3V  
  - Connect **GND** to GND  

> ⚠ Make sure not to connect the data line directly to a 5V logic pin; ESP32-S3 is 3.3V tolerant.

---

## Software Setup

### Install ESP-IDF

Follow the official guide: [ESP-IDF Setup](https://docs.espressif.com/projects/esp-idf/en/v5.4.1/esp32s3/get-started/index.html)

Check installation:

```bash
idf.py --version


idf.py add-dependency "espressif/led_strip^2.4.1"

dependencies:
  - "espressif/led_strip^2.4.1"

