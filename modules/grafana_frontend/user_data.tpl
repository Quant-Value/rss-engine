#!/bin/bash

set -x
# Update the system and install necessary dependencies
apt-get update -y
apt-get install -y unzip curl nfs-common git sudo python3-pip

# Set hostname
hostnamectl set-hostname "i4-rss-engine-demo.campusdual.mkcampus.com"

# Set /etc/rss-engine and /etc/rss-engine-dns-suffix
echo -n "${inumber}" > /etc/rss-engine-name
echo -n "${suffix_name}.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix

efs_dns_name=${efs_dns_name}


# Montar EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 $efs_dns_name:/ /mnt/efs

# Configurar el montaje persistente en fstab para reinicios
echo '$efs_dns_name:/ /mnt/efs nfs4 defaults 0 0' | sudo tee -a /etc/fstab

# Establecer los permisos correctos en el EFS
sudo chown -R 1000:1000 /mnt/efs/

log_message "EFS montado"

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

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


#Añadir ubuntu a grupo docker y reiniciar servicio docker
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

private_ip=$(hostname -I | awk '{print $1}')
instance_id=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=private-ip-address,Values=$private_ip" --query "Reservations[0].Instances[0].InstanceId" --output text)
# Get IP addresses
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region eu-west-3)

record_name="$(cat /etc/rss-engine-name)$(cat /etc/rss-engine-dns-suffix)"
zone_id=${zone}

# Set Route 53 DNS records for the EC2 instance (Public and Private IPs)
aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch "{
    \"Changes\": [
        {
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$record_name\",
                \"Type\": \"A\",
                \"TTL\": 60,
                \"ResourceRecords\": [{\"Value\": \"$PUBLIC_IP\"}]
            }
        }
    ]
}"



# Crear un servicio systemd para actualizar el DNS en cada reinicio
sudo tee /usr/local/bin/update-dns.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

instance_id=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=I4_instance" --query "Reservations[0].Instances[0].InstanceId" --output text)

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region eu-west-3)



record_name="i4-rss-engine-demo.campusdual.mkcampus.com"
zone_id=${zone}

aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch "{
    \"Changes\": [
        {
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$record_name\",
                \"Type\": \"A\",
                \"TTL\": 60,
                \"ResourceRecords\": [{\"Value\": \"$PUBLIC_IP\"}]
            }
        }
    ]
}"
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

# Añadir ubuntu a grupo docker y reiniciar servicio docker
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

curl -o /home/ubuntu/docker-compose.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/grafana/docker-compose.yml

mkdir /home/ubuntu/conf
# Retrieve the secret from AWS Secrets Manager
secret_value=$(aws secretsmanager get-secret-value --secret-id "rss-engine-imatia" --query SecretString --output text)
# Extract the 'elasticpass' field from the JSON secret
elasticpass=$(echo "$secret_value" | jq -r '.elasticpass')
# Path to the custom.ini file
config_file="/home/ubuntu/conf/custom.ini"
# Create or overwrite the custom.ini file with the admin password value
echo -e "[security]\n\nadmin_user = admin\nadmin_password = $elasticpass" > "$config_file"

# Confirm the update
echo "Password saved to $config_file"

mkdir /home/ubuntu/datasources
curl -o /home/ubuntu/datasources/prometheus-datasource.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/grafana/prometheus-datasource.yml

docker compose -f /home/ubuntu/docker-compose.yml up -d
