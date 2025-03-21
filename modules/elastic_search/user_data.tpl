#!/bin/bash
# Actualizar paquetes e instalar dependencias

sudo apt-get update -y
sudo apt-get install -y nfs-common unzip dos2unix curl lsb-release python3-apt

# Guardar el ID de la instancia y el DNS en archivos
echo "${instance_id}" > /etc/rss-engine-name
echo "-rss-engine-demo.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix
echo "${zone}" > /etc/zone_id

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
#zone_id="Z06113313M7JJFJ9M7HM8"  # ID de tu zona de Route 53
zone_id=${zone}
record_name="${instance_id}-rss-engine-demo.campusdual.mkcampus.com"
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

sudo tee /usr/local/bin/update-dns.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

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
zone_id=$(cat /etc/zone_id)
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

ssh-keygen -t rsa -b 2048 -f /home/ubuntu/.ssh/id_rsa -N ""
cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys

curl -o /home/ubuntu/Dockerfile.ansible https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/dockerfiles/Dockerfile.ansible

curl -o /home/ubuntu/Dockerfile https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/dockerfiles/Dockerfile.elastic
curl -o /home/ubuntu/docker-compose.yml.j2 https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/ElasticSearch/docker-compose.yml.j2
curl -o /home/ubuntu/install2.yml  https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/ElasticSearch/install2.yml 

sudo usermod -aG docker ubuntu
sudo systemctl restart docker

sudo docker build -t ansible-local -f /home/ubuntu/Dockerfile.ansible  /home/ubuntu

sudo mkdir /home/ubuntu/ca
#sudo openssl genpkey -algorithm RSA -out /home/ubuntu/ca/ca.key -pkeyopt rsa_keygen_bits:2048

#sudo openssl req -new -x509 -key /home/ubuntu/ca/ca.key -out /home/ubuntu/ca/ca.crt -days 3650 -subj "/C=US/ST=California/L=Los Angeles/O=MyOrg/OU=MyUnit/CN=example.com/emailAddress=email@example.com"

aws s3 cp s3://proyecto-devops-grupo-dos-paris/certs-ssl/ /home/ubuntu/ca --recursive 
#aws acm get-certificate --certificate-arn arn:aws:acm:eu-west-3:248189943700:certificate/d57d01fd-1847-4b43-b968-0af670c6461f --query "Certificate" --output text > ca.crt

hosts_file="/home/ubuntu/hosts.ini"
# Generar el archivo hosts.ini
echo "[webserver]" > $hosts_file
echo "$private_ip ansible_user=ubuntu" >> $hosts_file

# 4. Ejecutar el playbook de Ansible dentro de un contenedor Docker
sudo docker run --rm -v /home/ubuntu:/ansible/playbooks -v /home/ubuntu/.ssh:/root/.ssh \
--network host -e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no" -e NUM_NODES=${cantidad} -e INDEX=${index} \
--privileged --name ansible-playbook-container --entrypoint "/bin/bash" ansible-local  -c "ansible-playbook -i /ansible/playbooks/hosts.ini /ansible/playbooks/install2.yml  "


