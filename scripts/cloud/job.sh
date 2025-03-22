#!/bin/bash

# Comprobar si se ha proporcionado la URL como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar la URL del archivo WARC.WAT como argumento."
  exit 1
fi
#crawl-data/CC-MAIN-2025-05/segments/1736703701202.99/wat/CC-MAIN-20250126103503-20250126133503-00899.warc.wat.gz
# URL base de S3
BASE_URL="s3://commoncrawl/"

# Concatenar la URL base con el argumento pasado
URL="${BASE_URL}${1}"

echo "Descargando y procesando el archivo desde $URL..."

archivo_temp=$(mktemp)
# Descargar el archivo desde S3 y descomprimirlo en una variable
aws s3 cp "$URL" - | gunzip | grep -E '^{\"Container' | jq '.Envelope.["Payload-Metadata"].["HTTP-Response-Metadata"].["HTML-Metadata"].["Head"].Link, .Links' | grep -vx "null" | jq .[] | jq -r 'select(.type == "application/rss+xml") | .url' > "$archivo_temp"


#cat "$archivo_temp" | grep "http*" |  
urls_json=$(cat "$archivo_temp" | grep "http*" | jq -R . | jq -s '{urls: .}')

#urls_json_p=$(cat "$archivo_temp" | grep "http*" | head -n 10 | jq -R . | jq -s '{urls: .}')

#echo "$urls_json_p"  > output.json
#formato esperado {"urls": ["",""]}

rm "$archivo_temp"

archivo_temp2=$(mktemp)

echo "$urls_json" > $archivo_temp2

./process_rss_batch.sh "$archivo_temp2"

echo "Proceso completado."
