#!/bin/bash
#set -x

ES_USERNAME="elastic"
AWS_ELASTICSEARCH_ALB_DNS="i0-demo-rss-engine-demo.campusdual.mkcampus.com"
source .env
#source .env
INDEX_DEST="feed_items_demo"


# Comprobar si se ha proporcionado el archivo como argumento
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar el nombre del archivo JSON como argumento."
  exit 1
fi

# Leer el contenido del archivo JSON y parsearlo usando jq
archivo_json="$1"

# Leer las URLs desde el archivo JSON y convertirlas en un array de Bash
IFS=$'\n' read -rd '' -a URLS <<< "$(jq -r '.urls[]' "$archivo_json")"

# Leer las URLs desde el archivo JSON y convertir en un array de Bash
#IFS=$'\n' read -rd '' -a URLS <<< "$(echo "$1" | jq -r '.urls[]')"

#echo $URLS
total_urls=0
failed_urls=0
total_items=0
failed_processing=0
successful_urls=0
start_time=$(date +%s)

# Procesar cada URL proporcionada
for url in "${URLS[@]}"; do
  total_urls=$((total_urls + 1))
  echo "Procesando la URL: $url"
  
  # Descargar el contenido del archivo XML
  temp_file=$(mktemp)
  curl -s --max-time 25 "$url" -o "$temp_file"


  # Verificar si el archivo temporal contiene datos
  if [ ! -s "$temp_file" ]; then
    echo "Error: No se pudo descargar contenido o el archivo está vacío para la URL $url."
    failed_urls=$((failed_urls + 1)) # METRICA
    rm "$temp_file"
    continue  # Saltar esta URL y seguir con la siguiente
  fi

  # Procesar el feed RSS y guardarlo en JSON para revisión
  processed_items=0 # METRICA

  items_data=$(xq -j $temp_file | jq -c '.rss.channel | {
    feed_source_url: .link[0],  # Extraemos solo la primera URL
    feed_type: "RSS",
    items: [.item[] | {
        item_guid: .guid["#text"],  # Extraemos el valor de item_guid
        item_title: .title,
        item_url: .link,
        item_description: (.description // null)  # Si está vacío, asignamos null
    }]
  }' | jq -c '.items[] | { "index": { "_index": "feed_items_demo" } } + {
      item_guid: .item_guid,
      item_title: .item_title,
      item_url: .item_url,
      item_description: (.item_description // null)  # Usar null si está vacío
  }')

  
  if [ -n "$items_data" ]; then
    #echo $items_data
    #curl -X POST "$AWS_ELASTICSEARCH_ALB_DNS:9200/${INDEX_DEST}/_bulk" -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type: application/x-ndjson" --data-binary "$items_data"
  # Asegúrate de agregar un salto de línea al final
    echo -e "$items_data\n" | curl -X POST "$AWS_ELASTICSEARCH_ALB_DNS:9200/${INDEX_DEST}/_bulk" -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type: application/x-ndjson" --data-binary @-
    successful_urls=$((successful_urls + 1)) # METRICA
    item_count=$(echo "$items_data" | wc -l)
    total_items=$((total_items + item_count))
    echo "$url procesada correctamente?"
  else
    failed_processing=$((failed_processing + 1)) # METRICA
  fi

  # Limpiar archivos temporales
  rm "$temp_file"
done

end_time=$(date +%s) # METRICA
elapsed_time=$((end_time - start_time)) # METRICA


# Crear el JSON con las métricas
# Crear el JSON con las métricas
JSON=$(cat <<-EOF
{
  "total_urls": $total_urls,
  "failed_urls": $failed_urls,
  "total_items": $total_items,
  "failed_processing": $failed_processing,
  "successful_urls": $successful_urls,
  "elapsed_time": $elapsed_time
}
EOF
)


echo $JSON > out.json
# Enviar el JSON con métricas a Prometheus
./metrics_rss.sh "$JSON"
#./metrics_rss.sh "$JSON"
echo "Proceso completado."

rm "$archivo_json"