#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_http_client.h"
#include "esp_https_ota.h"
#include "wifi.h"

static const char *TAG = "OTA_FINAL";
extern const uint8_t server_cert_pem_start[] asm("_binary_ca_crt_start");

void start_https_ota(void)
{
    ESP_LOGI(TAG, "Starting Manual Flash Write...");

    esp_http_client_config_t config = {
        .url = "https://192.168.4.126/mqtt_demo.bin",
        .cert_pem = (const char *)server_cert_pem_start,
        .timeout_ms = 15000,
        .buffer_size = 4096,
        .keep_alive_enable = false,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);
    esp_err_t err = esp_http_client_open(client, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open HTTP connection");
        return;
    }

    int content_length = esp_http_client_fetch_headers(client);
    if (content_length <= 0) {
        ESP_LOGE(TAG, "Invalid content length");
        return;
    }

    // Prepare OTA
    const esp_partition_t *update_partition = esp_ota_get_next_update_partition(NULL);
    esp_ota_handle_t update_handle = 0;
    esp_ota_begin(update_partition, OTA_SIZE_UNKNOWN, &update_handle);

    char *upgrade_data_buf = (char *)malloc(4096);
    int binary_file_len = 0;

    while (1) {
        int data_read = esp_http_client_read(client, upgrade_data_buf, 4096);
        if (data_read == 0) {
            break; // Finished
        } else if (data_read < 0) {
            ESP_LOGE(TAG, "Error: SSL Data Read Error");
            break;
        }
        
        // Directly write to flash
        esp_ota_write(update_handle, (const void *)upgrade_data_buf, data_read);
        binary_file_len += data_read;
        ESP_LOGI(TAG, "Written: %d bytes", binary_file_len);
    }

    esp_ota_end(update_handle);
    esp_ota_set_boot_partition(update_partition);
    
    ESP_LOGI(TAG, "OTA Complete. Total: %d bytes. Rebooting...", binary_file_len);
    free(upgrade_data_buf);
    esp_http_client_cleanup(client);
    vTaskDelay(pdMS_TO_TICKS(2000));
    esp_restart();
}

void ota_task(void *pvParam)
{
    vTaskDelay(pdMS_TO_TICKS(5000));
    start_https_ota();
    vTaskDelete(NULL);
}