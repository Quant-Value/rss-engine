#!/bin/bash
#METRICS_URL="http://i3-demo-rss-engine-demo.campusdual.mkcampus.com:4318/v1/metrics"
#set -x

# Asegurarse de que se pase el JSON como argumento
if [ $# -eq 0 ]; then
  echo "Por favor, proporciona el archivo JSON de métricas como argumento."
  exit 1
fi



# Leer el JSON
#JSON=$(echo "$1" | jq .)
echo "$1"
# Extraer las métricas del JSON
total_urls=$(echo "$1" | jq -r '.total_urls' )
failed_urls=$(echo "$1" | jq -r '.failed_urls')
successful_urls=$(echo "$1"  | jq -r '.successful_urls')
total_items=$(echo "$1"  | jq -r '.total_items' )
elapsed_time=$(echo "$1"  | jq -r '.elapsed_time')


# Definir el timestamp
timestamp=$(date +%s%N)
# Estructura base para el JSON de métricas
JSON_TEMPLATE=$(cat <<-_JSON_
{
  "resourceMetrics": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": {
              "stringValue": "job-crawler"
            }
          }
        ]
      },
      "scopeMetrics": [
        {
          "scope": {
            "name": "job-crawler",
            "version": "1.0.0",
            "attributes": [
              {
                "key": "job.scope",
                "value": {
                  "stringValue": "feed-processing"
                }
              }
            ]
          },
          "metrics": [
            {
              "name": "total_urls",
              "unit": "1",
              "description": "Total URLs procesadas",
              "sum": {
                "aggregationTemporality": 1,
                "isMonotonic": true,
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "startTimeUnixNano": 0,
                    "timeUnixNano": 0,
                    "attributes": [
                      {
                        "key": "url.processing.total",
                        "value": {
                          "stringValue": "0"
                        }
                      }
                    ]
                  }
                ]
              }
            },
            {
              "name": "failed_urls",
              "unit": "1",
              "description": "URLs fallidas",
              "sum": {
                "aggregationTemporality": 1,
                "isMonotonic": true,
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "startTimeUnixNano": 0,
                    "timeUnixNano": 0,
                    "attributes": [
                      {
                        "key": "url.failure",
                        "value": {
                          "stringValue": "0"
                        }
                      }
                    ]
                  }
                ]
              }
            },
            {
              "name": "successful_urls",
              "unit": "1",
              "description": "URLs procesadas con éxito",
              "sum": {
                "aggregationTemporality": 1,
                "isMonotonic": true,
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "startTimeUnixNano": 0,
                    "timeUnixNano": 0,
                    "attributes": [
                      {
                        "key": "url.success",
                        "value": {
                          "stringValue": "0"
                        }
                      }
                    ]
                  }
                ]
              }
            },
            {
              "name": "total_items",
              "unit": "1",
              "description": "Total de items procesados",
              "sum": {
                "aggregationTemporality": 1,
                "isMonotonic": true,
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "startTimeUnixNano": 0,
                    "timeUnixNano": 0,
                    "attributes": [
                      {
                        "key": "items.total",
                        "value": {
                          "stringValue": "0"
                        }
                      }
                    ]
                  }
                ]
              }
            },
            {
              "name": "elapsed_time",
              "unit": "seconds",
              "description": "Tiempo de ejecución total",
              "gauge": {
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "timeUnixNano": 0,
                    "attributes": [
                      {
                        "key": "execution.time",
                        "value": {
                          "stringValue": "0"
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
_JSON_

)

# Crear el JSON con métricas y valores dinámicos
JSON=$(echo "$JSON_TEMPLATE" | jq -c \
  --arg total_urls "$total_urls" \
  --arg failed_urls "$failed_urls" \
  --arg successful_urls "$successful_urls" \
  --arg total_items "$total_items" \
  --arg elapsed_time "$elapsed_time" \
  --arg timestamp "$timestamp" \
  '
    # Actualizamos cada métrica existente:
    (.resourceMetrics[0].scopeMetrics[0].metrics[] | select(.name=="total_urls").sum.dataPoints[0])
      |= (. as $dp 
            | .asDouble = ($total_urls | tonumber) 
            | .startTimeUnixNano = ($timestamp | tonumber) 
            | .timeUnixNano = ($timestamp | tonumber) 
            | .attributes[0].value.stringValue = ($total_urls))
    
    | (.resourceMetrics[0].scopeMetrics[0].metrics[] | select(.name=="failed_urls").sum.dataPoints[0])
      |= (. as $dp 
            | .asDouble = ($failed_urls | tonumber) 
            | .startTimeUnixNano = ($timestamp | tonumber) 
            | .timeUnixNano = ($timestamp | tonumber) 
            | .attributes[0].value.stringValue = ($failed_urls))
    
    | (.resourceMetrics[0].scopeMetrics[0].metrics[] | select(.name=="successful_urls").sum.dataPoints[0])
      |= (. as $dp 
            | .asDouble = ($successful_urls | tonumber) 
            | .startTimeUnixNano = ($timestamp | tonumber) 
            | .timeUnixNano = ($timestamp | tonumber) 
            | .attributes[0].value.stringValue = ($successful_urls))
    
    | (.resourceMetrics[0].scopeMetrics[0].metrics[] | select(.name=="total_items").sum.dataPoints[0])
      |= (. as $dp 
            | .asDouble = ($total_items | tonumber) 
            | .startTimeUnixNano = ($timestamp | tonumber) 
            | .timeUnixNano = ($timestamp | tonumber) 
            | .attributes[0].value.stringValue = ($total_items))
    
    | (.resourceMetrics[0].scopeMetrics[0].metrics[] | select(.name=="elapsed_time").gauge.dataPoints[0])
      |= (. as $dp 
            | .asDouble = ($elapsed_time | tonumber) 
            | .timeUnixNano = ($timestamp | tonumber) 
            | .attributes[0].value.stringValue = ($elapsed_time))
    
  ')

# Guardar las métricas en un archivo JSON

echo "$JSON" > metrics_output.json



curl -v -L -X POST "$METRICS_URL" -H "Content-Type: application/json" --data "$JSON"
echo "\n\n"
echo "Métricas enviadas a $METRICS_URL"
echo "\n\n"