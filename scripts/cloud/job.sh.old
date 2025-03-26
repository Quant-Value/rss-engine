#!/bin/bash

# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi
#crawl-data/CC-MAIN-2025-05/segments/1736703701202.99/wat/CC-MAIN-20250126103503-20250126133503-00899.warc.wat.gz
#s3://commoncrawl/crawl-data/CC-MAIN-2025-05/segments/1736703701202.99/wat/CC-MAIN-20250126103503-20250126133503-00899.warc.wat.gz
# URL base de S3
BASE_URL="s3://commoncrawl/"

# Concatenar la URL base con el argumento pasado
URL="${BASE_URL}${1}"

echo "Descargando y procesando el archivo desde $URL..."

# Descargar y procesar el archivo directamente sin archivos temporales
urls_json=$(aws s3 cp "$URL" - | gunzip |  grep -E '^\{\"Container' | \
  jq -r 'select(.Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link) | .Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link, .Links' | \
  grep -v "null"| jq .[] | jq -r 'select(.type == "application/rss+xml") | .url'|grep "http*"| jq -R . | jq -s '{urls: .}' )

# Si no se obtiene ninguna URL, mostrar un mensaje de advertencia
if [ -z "$urls_json" ]; then
  echo "No se encontraron URLs válidas."
  exit 2
fi
#echo "$urls_json"
# Guardar el JSON de URLs en un archivo temporal para ser procesado por otro script
echo "$urls_json" | ./process_rss_batch.sh

echo "Proceso completado."
