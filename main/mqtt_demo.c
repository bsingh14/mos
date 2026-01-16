#include <stdio.h>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"

#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "mqtt_client.h"
#include "led_strip.h"
#include "esp_netif.h"

#define WIFI_SSID "freedom"
#define WIFI_PASS "6477164900"

#define LED_STRIP_GPIO GPIO_NUM_48
#define LED_STRIP_RMT_CHANNEL 0

#define MQTT_BROKER_URI "mqtts://192.168.4.126:8883"

static const char *TAG = "MQTT_DEMO";
static led_strip_handle_t led_strip;

extern const uint8_t ca_pem_start[] asm("_binary_ca_pem_start");
extern const uint8_t ca_pem_end[]   asm("_binary_ca_pem_end");

extern const uint8_t client_cert_pem_start[] asm("_binary_client_crt_start");
extern const uint8_t client_cert_pem_end[]   asm("_binary_client_crt_end");

extern const uint8_t client_key_pem_start[] asm("_binary_client_key_start");
extern const uint8_t client_key_pem_end[]   asm("_binary_client_key_end");



/* ===== LED Control ===== */

static void led_set_off(void)
{
    led_strip_clear(led_strip);
    led_strip_refresh(led_strip);
}

static void led_set_red(void)
{
    led_strip_set_pixel(led_strip, 0, 50, 0, 0);
    led_strip_refresh(led_strip);
}

static void led_set_green(void)
{
    led_strip_set_pixel(led_strip, 0, 0, 50, 0);
    led_strip_refresh(led_strip);
}

static void led_set_blue(void)
{
    led_strip_set_pixel(led_strip, 0, 0, 0, 50);
    led_strip_refresh(led_strip);
}

static void led_init(void)
{
    led_strip_config_t strip_config = {
        .strip_gpio_num = LED_STRIP_GPIO,
        .max_leds = 1,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model = LED_MODEL_WS2812,
        .flags.invert_out = false,
    };

    led_strip_rmt_config_t rmt_config = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 10 * 1000 * 1000,
        .mem_block_symbols = 64,
        .flags.with_dma = false,
    };

    led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip);
    //led_strip_clear(led_strip);
    //led_strip_refresh(led_strip);
    led_set_red();
}

/* ===== Wi-Fi ===== */

static void wifi_event_handler(void *arg,
                               esp_event_base_t event_base,
                               int32_t event_id,
                               void *event_data)
{
    if (event_base == WIFI_EVENT &&
        event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == IP_EVENT &&
               event_id == IP_EVENT_STA_GOT_IP) {
        ESP_LOGI(TAG, "Wi-Fi connected");
    } else if (event_base == WIFI_EVENT &&
               event_id == WIFI_EVENT_STA_DISCONNECTED) {
        ESP_LOGW(TAG, "Wi-Fi disconnected, retrying...");
        esp_wifi_connect();
    }
}

static void wifi_init_sta(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(
        esp_event_handler_instance_register(
            WIFI_EVENT,
            ESP_EVENT_ANY_ID,
            &wifi_event_handler,
            NULL,
            NULL));

    ESP_ERROR_CHECK(
        esp_event_handler_instance_register(
            IP_EVENT,
            IP_EVENT_STA_GOT_IP,
            &wifi_event_handler,
            NULL,
            NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASS,
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());
}

/* ===== MQTT ===== */

static void mqtt_event_handler(void *handler_args,
                               esp_event_base_t base,
                               int32_t event_id,
                               void *event_data)
{
    esp_mqtt_event_handle_t event = event_data;

    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT connected");

            esp_mqtt_client_subscribe(
                event->client,
                "esp32/mqtt_first_device/cmd",
                0);

            esp_mqtt_client_publish(
                event->client,
                "esp32/mqtt_first_device/status",
                "online",
                0, 1, 0);
            break;

        case MQTT_EVENT_DATA:
            ESP_LOGI(TAG, "Topic: %.*s", event->topic_len, event->topic);
            ESP_LOGI(TAG, "Data: %.*s", event->data_len, event->data);

            if (strncmp(event->topic,
                        "esp32/mqtt_first_device/cmd",
                        event->topic_len) == 0) {

                if (strncmp(event->data, "OFF", event->data_len) == 0) {
                    led_set_off();
                    esp_mqtt_client_publish(event->client,
                        "esp32/mqtt_first_device/status",
                        "LED_OFF", 0, 1, 0);
                } else if (strncmp(event->data, "RED", event->data_len) == 0) {
                    led_set_red();
                    esp_mqtt_client_publish(event->client,
                        "esp32/mqtt_first_device/status",
                        "LED_RED", 0, 1, 0);
                } else if (strncmp(event->data, "GREEN", event->data_len) == 0) {
                    led_set_green();
                    esp_mqtt_client_publish(event->client,
                        "esp32/mqtt_first_device/status",
                        "LED_GREEN", 0, 1, 0);
                } else if (strncmp(event->data, "BLUE", event->data_len) == 0) {
                    led_set_blue();
                    esp_mqtt_client_publish(event->client,
                        "esp32/mqtt_first_device/status",
                        "LED_BLUE", 0, 1, 0);
                }
            }
            break;

        default:
            break;
    }
}

static void mqtt_app_start(void)
{
    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = MQTT_BROKER_URI,
        /*.broker.address.transport = MQTT_TRANSPORT_OVER_SSL,*/

        .broker.verification.certificate =
            (const char *)ca_pem_start,

        .credentials.authentication.certificate =
            (const char *)client_cert_pem_start,

        .credentials.authentication.key =
            (const char *)client_key_pem_start,

        .credentials.client_id = "esp32s3_mqtt_01",

    };

    esp_mqtt_client_handle_t client =
        esp_mqtt_client_init(&mqtt_cfg);

    esp_mqtt_client_register_event(
        client,
        ESP_EVENT_ANY_ID,
        mqtt_event_handler,
        NULL);

    esp_mqtt_client_start(client);
}

/* ===== app_main ===== */

void app_main(void)
{
    led_init();
    wifi_init_sta();

    vTaskDelay(pdMS_TO_TICKS(5000)); // wait for Wi-Fi

    mqtt_app_start();
}
