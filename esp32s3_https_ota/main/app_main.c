#include "wifi.c"   // or proper header
#include "ota.c"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void)
{
    ESP_LOGI("RESET", "Reset reason: %d", esp_reset_reason());

    wifi_init_sta();   // safe now

    // Wait until Wi-Fi connected
    while (!wifi_is_connected()) {
        vTaskDelay(pdMS_TO_TICKS(500));
    }

    ESP_LOGI("OTA", "Wi-Fi connected, starting OTA...");
    start_https_ota(); // your OTA function
}
