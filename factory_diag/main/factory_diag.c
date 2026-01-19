#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_chip_info.h"

#include "esp_mac.h"
#include "esp_log.h"


void app_main(void)
{
    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);

    printf("\n=== FACTORY DIAGNOSTICS ===\n");
    printf("Chip: ESP32-S3\n");
    printf("Cores: %d\n", chip_info.cores);
    printf("Revision: %d\n", chip_info.revision);
    printf("Features: %s%s\n",
           (chip_info.features & CHIP_FEATURE_WIFI_BGN) ? "WiFi " : "",
           (chip_info.features & CHIP_FEATURE_BT) ? "BT" : "");

    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);

    ESP_LOGI("FACTORY", "WiFi STA MAC: %02X:%02X:%02X:%02X:%02X:%02X",
            mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

    while (1) {
        //ESP_LOGI("FACTORY", "Factory diag alive");
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}
