#include "wifi.c"   // or proper header
#include "ota.c"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"


extern void ota_task(void *pvParam);

static const char *TAG_HTTP = "HTTP_TEST";

void test_server_connection(void)
{
    if (!wifi_is_connected()) {
        ESP_LOGE(TAG_HTTP, "Wi-Fi not connected!");
        return;
    }

    esp_http_client_config_t config = {
        .url = "https://192.168.4.126/esp32s3_v2.bin",  // your OTA server
        .timeout_ms = 10000,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);

    esp_err_t err = esp_http_client_perform(client);
    if (err == ESP_OK) {
        int status = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG_HTTP, "Server reachable! HTTP Status = %d", status);
    } else {
        ESP_LOGE(TAG_HTTP, "Cannot reach server: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
}

static const char *TAG_HTTPS = "HTTPS_TEST";

/* Embedded CA certificate */
extern const uint8_t server_cert_pem_start[] asm("_binary_ca_crt_start");

esp_err_t test_server_connection_https(const char *url)
{
    ESP_LOGI(TAG_HTTPS, "Testing HTTPS connection to: %s", url);

    esp_http_client_config_t config = {
        .url = url,
        .method = HTTP_METHOD_HEAD,   // HEAD = lightweight test
        .cert_pem = (const char *)server_cert_pem_start,
        .timeout_ms = 5000,
        .transport_type = HTTP_TRANSPORT_OVER_SSL,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);
    if (client == NULL) {
        ESP_LOGE(TAG_HTTPS, "Failed to init HTTP client");
        return ESP_FAIL;
    }

    esp_err_t err = esp_http_client_perform(client);

    if (err == ESP_OK) {
        int status = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG_HTTPS, "HTTPS reachable, status = %d", status);
    } else {
        ESP_LOGE(TAG_HTTPS, "HTTPS connection failed: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
    return err;
}

void app_main(void)
{
    ESP_LOGI("RESET", "Reset reason: %d", esp_reset_reason());

    wifi_init_sta();   // safe now

    // Wait until Wi-Fi connected
    while (!wifi_is_connected()) {
        vTaskDelay(pdMS_TO_TICKS(500));
    }

    //test_server_connection(); // <--- debug server connectivity
    //test_server_connection_https("https://192.168.4.126/esp32s3_https_ota_demo.bin");

    xTaskCreate(
        ota_task,
        "ota_task",
        8192,      // OTA needs stack
        NULL,
        5,
        NULL
    );

    //ESP_LOGI("OTA", "Wi-Fi connected, starting OTA...");
    //start_https_ota(); // your OTA function

    //while(1){
    //    vTaskDelay(pdMS_TO_TICKS(1000));
    //}
}
