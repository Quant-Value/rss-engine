#!/bin/bash


# Actualizar paquetes e instalar dependencias
LOG_FILE="/var/log/mi_script.log"

# Función para agregar logs al archivo
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}
# Actualizar paquetes e instalar dependencias

sudo apt-get update -y
sudo apt-get install -y nfs-common unzip dos2unix curl lsb-release python3-apt

# Guardar el ID de la instancia y el DNS en archivos
echo "${instance_id}" > /etc/rss-engine-name
echo "-rss-engine-demo.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix

# Instalar Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar Docker
sudo docker --version

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

              # Obtener la IP privada
private_ip=$(hostname -I | awk '{print $1}')
# Leer los archivos para obtener los valores


              # Añadir la IP privada al registro de Route 53 (reemplazar los valores según sea necesario)
zone_id=${zone}  # ID de tu zona de Route 53
record_name="${record_name}"
aws route53 change-resource-record-sets \
                --hosted-zone-id $zone_id \
                --change-batch '{
                  "Changes": [
                    {
                      "Action": "UPSERT",
                      "ResourceRecordSet": {
                        "Name": "'$record_name'",
                        "Type": "A",
                        "TTL": 300,
                        "ResourceRecords": [{"Value": "'$private_ip'"}]
                      }
                    }
                  ]
                }'

              # Crear un servicio systemd para actualizar el DNS en cada reinicio
# Crear un servicio systemd para actualizar el DNS en cada reinicio
# Crear un servicio systemd para actualizar el DNS en cada reinicio
sudo tee /usr/local/bin/update-dns.sh > /dev/null <<'EOF'
#!/bin/bash
set -e
zone_id=${zone}
private_ip=$(hostname -I | awk '{print $1}')
record_name="$(cat /etc/rss-engine-name | tr -d '\n')$(cat /etc/rss-engine-dns-suffix | tr -d '\n')"
echo "IP y record_name: $private_ip $record_name"

json=$(cat <<EOT
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$record_name",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$private_ip"
          }
        ]
      }
    }
  ]
}
EOT
)

echo "JSON generado: $json"
aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch "$json"
EOF


#Dar permisos al script para ejecutarse
sudo chmod +x /usr/local/bin/update-dns.sh

#Condiguración del servicio de systemd llamando al script
sudo tee /etc/systemd/system/update-dns.service > /dev/null <<EOF
[Unit]
Description=Actualizar registro DNS en Route 53 con la IP privada
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-dns.sh

[Install]
WantedBy=multi-user.target
EOF



              # Habilitar el servicio para que se ejecute al iniciar la instancia
sudo systemctl daemon-reload
sudo systemctl enable update-dns.service
sudo systemctl start update-dns.service

# Añadir variable de dns name de efs

efs_dns_name=${efs_dns_name}


# Montar EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 $efs_dns_name:/ /mnt/efs

# Configurar el montaje persistente en fstab para reinicios
echo '$efs_dns_name:/ /mnt/efs nfs4 defaults 0 0' | sudo tee -a /etc/fstab

# Establecer los permisos correctos en el EFS
sudo chown -R 1000:1000 /mnt/efs/



# Añadir ubuntu a grupo docker y reiniciar servicio docker

sudo usermod -aG docker ubuntu
sudo systemctl restart docker


# Función para esperar la propagación de los cambios DNS

wait_for_dns_resolution() {
  local dns_name=$1
  local port=$2
  local timeout=60  # Tiempo máximo de espera en segundos
  local interval=5  # Intervalo entre verificaciones en segundos
  local elapsed=0

  log_message "Esperando a la resolución correcta de DNS para $dns_name en el puerto $port..."

  # Esperar a que el puerto esté accesible
# Esperar a que el puerto esté accesible
while true; do
    # Resolver el DNS para obtener la IP
    resolved_ip=$(dig +short "$dns_name")
    
    if [ -z "$resolved_ip" ]; then
        log_message "No se pudo resolver el nombre DNS: $dns_name"
        return 1
    fi

    log_message "La IP resuelta para $dns_name es: $resolved_ip"
    
    # Intentar la conexión al puerto con nc
    nc -z -w 3 "$resolved_ip" "$port"
    
    if [ $? -eq 0 ]; then
        log_message "Conexión exitosa al puerto $port en $resolved_ip."
        break  # Salir del bucle si nc es exitoso
    fi

    # Incrementar el tiempo de espera y comprobar si se alcanzó el timeout
    elapsed=$((elapsed + interval))
    if [ $elapsed -ge $timeout ]; then
        log_message "Timeout alcanzado después de $timeout segundos. No se pudo conectar al puerto $port en $resolved_ip."
        return 1
    fi

    log_message "Esperando la conexión al puerto $port en $resolved_ip... (Intento $((elapsed / interval)))"
    sleep $interval
done


  log_message "Conexión exitosa al puerto $port en $resolved_ip."
  return 0
}

# Uso de la función
dns_name="${record_name}"
port=22
wait_for_dns_resolution "$dns_name" "$port"

# Descargar el playbook de Ansible
# Descargar los tres playbooks desde GitHub
curl -o /mnt/efs/otel/otel-collector-config.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/config/otel-collector-config.yml
curl -o /mnt/efs/prometheus/config/prometheus.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/config/prometheus.yml
curl -o /home/ubuntu/docker-compose.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/docker-compose.yml
curl -o /home/ubuntu/Dockerfile https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/dockerfiles/Dockerfile.prometheus

# Ejecutar los tres playbooks de Ansible dentro de un contenedor Docker,
# de forma que se ejecuten de forma secuencial (en cascada).

docker compose -f /home/ubuntu/docker-compose.yml up -d

