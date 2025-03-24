#!/bin/bash
SW_SERVER="13.36.243.52"
# URL de S3 del archivo comprimido de forma manual
bucket_url="s3://commoncrawl/crawl-data/CC-MAIN-2025-05/wat.paths.gz"

# Nombre del archivo comprimido (no es necesario almacenar el archivo descomprimido)
archivo_comprimido="archivo_descargado.gz"

# Descargar el archivo desde S3 usando AWS CLI y procesar directamente desde el pipe
echo "Descargando y procesando el archivo desde S3: $bucket_url..."


# O si prefieres usar `xargs` para paralelizar
#aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 1 ./app add -server http://${SW_SERVER}:8080 -cmd "bash -c \"(time ./scripts/job.sh {}) 2>&1 | grep real >> time.txt && aws s3 cp time.txt s3://proyecto-devops-grupo-dos/workers/$(hostname -I | awk '{print $1}') \"" -timeout 100

#aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 20 ./app add -server http://${SW_SERVER}:8080 -cmd "bash -c \"cd scripts &&./job.sh {}\"" -timeout 100
aws s3 cp "$bucket_url" - | gunzip -c| head -n 6  | xargs -I {} -P 20 ./app add -server http://${SW_SERVER}:8080 -cmd "bash -c \"cd scripts &&./job.sh {}\"" -timeout 500


#aws s3 cp "$bucket_url" - | gunzip -c | echo {}

#aws s3 cp "$bucket_url" - | gunzip -c | xargs -I {} -P 1 ./app add -server http://${SW_SERVER}:8080 -cmd " (time sleep 4 )2>&1 | grep real >> time.txt && aws s3 cp time.txt s3://proyecto-devops-grupo-dos/workers/$(hostname -I | awk '{print $1}')/time.txt " -timeout 15

echo "Proceso completado."
