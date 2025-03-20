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
record_name="${instance_id}-rss-engine-demo.campusdual.mkcampus.com.campusdual.mkcampus.com"
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
SERVICE_CONTENT=$(cat <<EOF
[Unit]
Description=Actualizar registro DNS en Route 53 con la IP privada
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c \
"private_ip=\$(hostname -I | awk '{print \$1}'); \
record_name=\$(cat /etc/rss-engine-name)\$(cat /etc/rss-engine-dns-suffix);echo \$private_ip \$record_name \
aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"\$record_name\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"\$private_ip\"}]}}]}'"
Restart=no

[Install]
WantedBy=multi-user.target
EOF
)
echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/update-dns.service > /dev/null

# el servicio funciona pero no acabo de entender porque funciona si al echo no le he puesto el ;

              # Habilitar el servicio para que se ejecute al iniciar la instancia
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


# Descargar el playbook de Ansible
curl -o /home/ubuntu/install.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/install.yml

# Ejecutar el playbook de Ansible dentro de un contenedor Docker
sudo docker run --rm -v /home/ubuntu:/ansible/playbooks\
  --network host \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no" \
  --privileged --name ansible-playbook-container \
  --entrypoint "/bin/sh" \
  alpine/ansible:2.18.1 -c "ansible-playbook /ansible/playbooks/install.yml"