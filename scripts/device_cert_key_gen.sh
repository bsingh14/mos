#!/bin/bash
# Script to generate client key and certificate for ESP32 devices
# Uses 4096-bit RSA keys
# Certificate serial number = ASCII hex of MAC + user-supplied serial
# Usage: ./generate_client_cert.sh <MAC_ADDRESS> <SERIAL_NUMBER>
# Example: ./generate_client_cert.sh AA:BB:CC:DD:EE:01 001

set -e  # Exit on any error

# --- 1️⃣ Check input ---
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <MAC_ADDRESS> <SERIAL_NUMBER>"
  echo "Example: $0 AA:BB:CC:DD:EE:01 001"
  exit 1
fi

# --- 2️⃣ Normalize MAC ---
MAC_RAW=$(echo "$1" | tr '[:lower:]' '[:upper:]')  # Uppercase MAC
USER_SERIAL=$2

# Remove colons for safe CN / filenames
DEVICE_MAC=$(echo "$MAC_RAW" | tr -d ':')
# Concatenate MAC + user serial
CERT_SERIAL_STR="${DEVICE_MAC}${USER_SERIAL}"

# Convert string to ASCII hex for OpenSSL serial
CERT_SERIAL_HEX=$(echo -n "$CERT_SERIAL_STR" | od -A n -t x1 | tr -d ' \n')

echo "Generating certificate for device: $DEVICE_MAC"
echo "Certificate serial (hex ASCII): $CERT_SERIAL_HEX"

# --- 3️⃣ Paths ---
STACK_DIR="$HOME/iiot-stack"
CERT_DIR="$STACK_DIR/config/certs"
cd "$CERT_DIR" || { echo "Error: Cert directory not found."; exit 1; }

CA_CERT="ca.crt"      # Your CA certificate
CA_KEY="ca.key"       # Your CA private key (keep secure/offline)
OUTPUT_DIR="$DEVICE_MAC"
mkdir -p "$OUTPUT_DIR"

# --- 4️⃣ Generate client private key (4096-bit) ---
openssl genrsa -out "$OUTPUT_DIR/client.key" 4096
echo "Client private key generated: $OUTPUT_DIR/client.key"

# --- 5️⃣ Generate CSR (common name = MAC) ---
openssl req -new -key "$OUTPUT_DIR/client.key" \
  -out "$OUTPUT_DIR/client.csr" \
  -subj "/CN=$DEVICE_MAC"
echo "CSR generated: $OUTPUT_DIR/client.csr"

# --- 6️⃣ Create per-device extensions ---
EXT_FILE="$OUTPUT_DIR/client.ext"
echo "extendedKeyUsage = clientAuth" > "$EXT_FILE"
echo "subjectAltName = DNS:$DEVICE_MAC" >> "$EXT_FILE"

# --- 7️⃣ Sign CSR with CA using ASCII hex serial ---
openssl x509 -req -in "$OUTPUT_DIR/client.csr" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" \
  -set_serial 0x"$CERT_SERIAL_HEX" \
  -out "$OUTPUT_DIR/client.crt" -days 365 \
  -extfile "$EXT_FILE"

# --- 8️⃣ Adjust permissions ---
chown $USER:$USER "$OUTPUT_DIR/client.key" "$OUTPUT_DIR/client.crt" "$OUTPUT_DIR/client.csr"
chmod 644 "$OUTPUT_DIR/client.key" "$OUTPUT_DIR/client.crt"

echo "✅ Client certificate and key ready for device $DEVICE_MAC"
echo "Directory: $OUTPUT_DIR"
echo "Certificate serial used (hex ASCII): $CERT_SERIAL_HEX"
