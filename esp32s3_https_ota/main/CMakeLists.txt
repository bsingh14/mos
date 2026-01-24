idf_component_register(
    SRCS "app_main.c" "wifi.c" "ota.c"
    INCLUDE_DIRS "."
    EMBED_TXTFILES "certs/ca.crt"
)
