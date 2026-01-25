#include <inttypes.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
//#include "wifi.h"   // simple Wi-Fi helper


static const char *TAG = "MAIN";

void app_main(void)
{
    ESP_LOGI(TAG, "Hello World! Reset reason: %d", esp_reset_reason());

    // Initialize Wi-Fi
   // wifi_init_sta();   // assumes wifi.c with wifi_is_connected()

    // Wait until connected
    /*while (!wifi_is_connected()) {
        vTaskDelay(pdMS_TO_TICKS(500));
    }*/

    //ESP_LOGI(TAG, "Wi-Fi connected, IP assigned");

    uint32_t seconds = 0;

    while (1) {
        ESP_LOGI(TAG, "Alive for %" PRIu32 " seconds", seconds++);
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
