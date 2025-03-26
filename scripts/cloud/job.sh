#!/bin/bash
set -x
# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi

# URL base de S3
BASE_URL="s3://commoncrawl/"

# Concatenar la URL base con el argumento pasado
URL="${BASE_URL}${1}"

# Variables para backoff
max_retries=5            # Número máximo de reintentos
retry_interval=1         # Tiempo inicial entre intentos (en segundos)
slowdown_backoff_factor=5 # Factor de backoff exponencial cuando recibimos un SlowDown
#backoff_factor=2         # Factor de multiplicación para el intervalo (normal)

echo "Descargando y procesando el archivo desde $URL..."

# Contador de intentos
attempt=1

# Intentar descargar el archivo con backoff
while : ; do
  # Intentar ejecutar el comando aws s3 cp y capturar el código de salida
  output=$(aws s3 cp "$URL" - 2>&1)
  exit_code=$?

  # Verificar si hubo un error de SlowDown
  if [[ "$output" == *"SlowDown"* ]]; then
    echo "Error: SlowDown detectado. Esperando antes de reintentar..."
    if [ "$attempt" -lt "$max_retries" ]; then
      echo "Intento $attempt fallido. Esperando $retry_interval segundos antes de intentar nuevamente..."
      sleep $retry_interval
      retry_interval=$((retry_interval * slowdown_backoff_factor))  # Backoff exponencial más agresivo para SlowDown
      attempt=$((attempt + 1))
      continue
    else
      echo "Error: No se pudo descargar el archivo después de $max_retries intentos."
      exit 2
    fi
  fi

  # Si la descarga fue exitosa
  if [ "$exit_code" -eq 0 ]; then
    urls_json=$(echo "$output" | gunzip | grep -E '^\{\"Container' | \
      jq -r 'select(.Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link) | .Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link, .Links' | \
      grep -v "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' | grep "http*" | jq -R . | jq -s '{urls: .}' )
    
    # Si no se obtiene ninguna URL, mostrar un mensaje de advertencia
    if [ -z "$urls_json" ]; then
      echo "No se encontraron URLs válidas."
      exit 2
    fi

    # Procesar el archivo de URLs
    echo "$urls_json" | ./process_rss_batch.sh

    echo "Proceso completado."
    exit 0
  fi

  # Si hubo otro tipo de error, manejar reintentos
  if [ "$attempt" -lt "$max_retries" ]; then
    echo "Intento $attempt fallido. Error: $output. Esperando $retry_interval segundos antes de intentar nuevamente..."
    sleep $retry_interval
    retry_interval=$((retry_interval * backoff_factor))  # Backoff exponencial
    attempt=$((attempt + 1))
  else
    echo "Error: No se pudo descargar el archivo después de $max_retries intentos. Mensaje de error: $output"
    exit 2
  fi
done
