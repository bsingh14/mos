#!/bin/bash

# Define the order of scripts to run
SCRIPTS=("setup_iiot.sh" "secure_mqtt.sh" "setup_mtls.sh")

echo "=========================================="
echo "   IIoT FACTORY STACK - MASTER DEPLOY"
echo "=========================================="

for script in "${SCRIPTS[@]}"; do
    if [[ -f "./$script" ]]; then
        echo "--> Running $script..."
        
        # Make sure it's executable
        chmod +x "$script"
        
        # Run the script and capture exit code
        ./"$script"
        
        if [[ $? -eq 0 ]]; then
            echo "SUCCESS: $script finished."
            echo "------------------------------------------"
        else
            echo "ERROR: $script failed. Stopping deployment."
            exit 1
        fi
    else
        echo "SKIPPING: $script not found in current directory."
    fi
done



echo "=========================================="
echo "   ALL SYSTEMS SECURED AND DEPLOYED"
echo "=========================================="

# Refresh group permissions for the current session
exec newgrp docker <<EONG
  cd ~/iiot-stack
  docker compose up -d
  echo "Stack started successfully!"
  echo "Access InfluxDB at http://$(hostname -I | awk '{print $1}'):8086"
EONG
