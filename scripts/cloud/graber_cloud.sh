#!/bin/bash

SW_SERVER="i8-demo-rss-engine-demo.campusdual.mkcampus.com"
bucket_url="s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz"
source .env
archivo_comprimido="archivo_descargado.gz"
ES_USERNAME="elastic"
INDEX_NAME="items-prueba"

echo "Verificando si el índice existe..."
curl -X PUT "i1-demo-rss-engine-demo.campusdual.mkcampus.com:9200/$INDEX_NAME" \
    -u "$ES_USERNAME:$ES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
          "settings": {
            "number_of_shards": 27,
            "number_of_replicas": 1
          },
          "mappings": {
            "properties": {
              "url": {
                "type": "text"
              },
              "fecha": {
                "type": "date"
              }
            }
          }
        }'

# Algoritmo de backoff
max_attempts=8
attempt=0
backoff_time=2  # Tiempo inicial de espera en segundos

while (( attempt < max_attempts )); do
    echo "Descargando y procesando el archivo desde S3: $bucket_url (Intento $((attempt + 1)))..."
    
    # Intenta ejecutar el comando
    if aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 20 docker exec -i myserver_add ./app-bluengo-worker add -server http://${SW_SERVER}:8080 -cmd "bash -c \"cd scripts && ./job.sh {}\"" -timeout 500; then
        echo "Descarga y procesamiento completados exitosamente."
        break  # Salir del bucle si tiene éxito
    else
        echo "Error al descargar o procesar el archivo. Esperando $backoff_time segundos antes de volver a intentar..."
        sleep $backoff_time
        backoff_time=$((backoff_time * 3))  # Duplicar el tiempo de espera
        ((attempt++))
    fi
done

if (( attempt == max_attempts )); then
    echo "Se alcanzó el número máximo de intentos. Abortando."
    exit 1
fi

echo "Proceso completado."
