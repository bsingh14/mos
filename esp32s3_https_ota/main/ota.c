#include "esp_https_ota.h"
#include "esp_log.h"
#include "esp_ota_ops.h"

static const char *TAG = "OTA";

extern const uint8_t server_cert_pem_start[] asm("_binary_ca_crt_start");

void start_https_ota(void)
{
    ESP_LOGI(TAG, "Starting HTTPS OTA...");

    esp_http_client_config_t http_cfg = {
        .url = "https://192.168.4.126/esp32s3_v2.bin",
        .cert_pem = (char *)server_cert_pem_start,
        .timeout_ms = 15000,
    };

    esp_https_ota_config_t ota_cfg = {
        .http_config = &http_cfg,
    };

    esp_err_t ret = esp_https_ota(&ota_cfg);

    if (ret == ESP_OK) {
        ESP_LOGI(TAG, "OTA successful, rebooting...");
        esp_restart();
    } else {
        ESP_LOGE(TAG, "OTA failed: %s", esp_err_to_name(ret));
    }
}
