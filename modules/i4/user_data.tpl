#!/bin/bash

set -x
# Update the system and install necessary dependencies
apt-get update -y
apt-get install -y unzip curl nfs-common git sudo docker.io python3-pip

# Set hostname
hostnamectl set-hostname i4-rss-engine-demo.campusdual.mkcampus.com

# Set /etc/rss-engine and /etc/rss-engine-dns-suffix
echo -n "i4" > /etc/rss-engine-name
echo -n "${instance_id}.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install Docker
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
sudo apt-get install -y docker-compose

# Install Ansible
sudo apt install -y ansible

# Ensure the playbook and docker-compose.yml file are available before running playbooks
mkdir -p /home/ubuntu/playbooks
curl -o /home/ubuntu/playbooks/install.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/main/ansible/grafana/install.yml
curl -o /home/ubuntu/playbooks/install2.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/main/ansible/grafana/install2.yml
curl -o /home/ubuntu/playbooks/install3.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/main/ansible/grafana/install3.yml
curl -o /home/ubuntu/docker/docker-compose.yml https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/main/ansible/grafana/docker-compose.yml

# Run the Ansible playbook (use the correct path to the playbook file)
cd /home/ubuntu/playbooks
ansible-playbook -i 127.0.0.1, install.yml
ansible-playbook -i 127.0.0.1, install2.yml
ansible-playbook -i 127.0.0.1, install3.yml

#Añadir ubuntu a grupo docker y reiniciar servicio docker
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Change directory to where docker-compose.yml is located
cd /home/ubuntu/docker

# Start Grafana using Docker Compose
sudo docker-compose up -d

instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=I4_instance" --query "Reservations[0].Instances[0].InstanceId" --output text)
# Get IP addresses
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region eu-west-3)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text --region eu-west-3)

record_name="$(cat /etc/rss-engine-name)$(cat /etc/rss-engine-dns-suffix)"


# Set Route 53 DNS records for the EC2 instance (Public and Private IPs)
aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "'$PUBLIC_IP'"}]
            }
        }
    ]
}'

aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "'$PRIVATE_IP'"}]
            }
        }
    ]
}'



# Run the Ansible playbook
cd /home/ubuntu/iX-rss-engine
ansible-playbook -i 127.0.0.1, playbook.yml

# Crear un servicio systemd para actualizar el DNS en cada reinicio
sudo tee /usr/local/bin/update-dns.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=I4_instance" --query "Reservations[0].Instances[0].InstanceId" --output text)

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region eu-west-3)

PRIVATE_IP=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text --region eu-west-3)

record_name="i4-rss-engine-demo.campusdual.mkcampus.com"


aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "'$PUBLIC_IP'"}]
            }
        }
    ]
}'

aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "'$PRIVATE_IP'"}]
            }
        }
    ]
}'
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