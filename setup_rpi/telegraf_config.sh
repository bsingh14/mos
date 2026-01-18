#!/bin/bash

STACK_DIR="$HOME/iiot-stack"
TELEGRAF_CONF="$STACK_DIR/telegraf_config/telegraf.conf"
CERT_DIR="$STACK_DIR/config/certs"

cat <<EOF > "$TELEGRAF_CONF"
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
  servers = ["ssl://mosquitto:8883"]
  topics = ["factory/#"]
  qos = 1
  client_id = "telegraf_factory"
  username = "factory_admin"
  password = "asbhatti"
  data_format = "json"
  json_string_fields = ["device_id"]
  tls_ca   = "/etc/telegraf/certs/ca.crt"
  tls_cert = "/etc/telegraf/certs/client.crt"
  tls_key  = "/etc/telegraf/certs/client.key"
  name_override = "factory_telemetry"
EOF

chmod 644 "$TELEGRAF_CONF"
echo "Telegraf configuration updated with MQTTS support."
