idf_component_register(
    SRCS "mqtt_demo.c"
    INCLUDE_DIRS "."
    EMBED_TXTFILES
        "certs/ca.pem"
        "certs/client.crt"
        "certs/client.key"
)
