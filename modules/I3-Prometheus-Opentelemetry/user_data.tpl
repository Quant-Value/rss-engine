#!/bin/bash
# Actualizar paquetes e instalar dependencias
set -x
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
zone_id="Z06113313M7JJFJ9M7HM8"  # ID de tu zona de Route 53
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
sudo tee /etc/systemd/system/update-dns.service > /dev/null <<EOSERV
[Unit]
Description=Actualizar registro DNS en Route53 con la IP privada
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'private_ip=\$(hostname -I | awk "{print \$1}"); record_name="${instance_id}-rss-engine-demo.campusdual.mkcampus.com"; aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch "{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"\$record_name\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"\$private_ip\"}]}}]}\"'
Restart=no

[Install]
WantedBy=multi-user.target
EOSERV


# Reemplazar el placeholder <RECORD_NAME> por el valor real usando sed
sudo sed -i "s|<RECORD_NAME>|${record_name}|g" /etc/systemd/system/update-dns.service

# Recargar systemd para que lea la nueva unidad, habilitar y arrancar el servicio
sudo systemctl daemon-reload
sudo systemctl enable update-dns.service
sudo systemctl start update-dns.service



# Montar EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs

# Configurar el montaje persistente en fstab para reinicios
echo 'fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs nfs4 defaults 0 0' | sudo tee -a /etc/fstab

# Establecer los permisos correctos en el EFS
sudo chown -R 1000:1000 /mnt/efs/

#Permisos ECR

aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 248189943700.dkr.ecr.eu-west-3.amazonaws.com

#Añadir ubuntu a grupo docker y reiniciar servicio docker

sudo usermod -aG docker ubuntu
sudo systemctl restart docker


# Descargar el playbook de Ansible
# Descargar los tres playbooks desde GitHub
curl -o /home/ubuntu/install.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/install.yml
curl -o /home/ubuntu/install2.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/install2.yml
curl -o /home/ubuntu/install3.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/Otel-Prometheus/install3.yml


# Ejecutar los tres playbooks de Ansible dentro de un contenedor Docker,
# de forma que se ejecuten de forma secuencial (en cascada).
sudo docker run --rm   -v /home/ubuntu:/home/ubuntu   -v /mnt/efs:/mnt/efs   --network host   --ulimit nofile=65536:65536   --ulimit nproc=65535   --ulimit memlock=-1   --privileged   -e ANSIBLE_HOST_KEY_CHECKING=False   -e ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"   demisto/ansible-runner:1.0.0.110653   sh -c "ansible-playbook /home/ubuntu/install.yml && ansible-playbook /home/ubuntu/install2.yml && ansible-playbook /home/ubuntu/install3.yml"
