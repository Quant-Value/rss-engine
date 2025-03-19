resource "aws_key_pair" "key" {
  key_name   = "my-ec2-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "public_ec2" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.key.key_name
  subnet_id       = var.subnet_ids
  disable_api_stop = false

  tags = {
    Name = "I4_instance",
    Grupo= "g2",
    DNS_NAME="I4"

  }

  # Crear un grupo de seguridad para permitir el acceso SSH
  vpc_security_group_ids = [aws_security_group.sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash

    # Set hostname
    hostnamectl set-hostname i4.g2-prometheus-lab.campusdual.mkcampus.com

    # Set /etc/rss-engine and /etc/rss-engine-dns-suffix
    echo "i4" > /etc/rss-engine
    echo "g2-prometheus-lab.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix

    # Install AWS CLI
    sudo apt update
    sudo apt install -y awscli

    # Get IP addresses
    PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

    # Set Route 53 DNS records for the EC2 instance (Public and Private IPs)
    aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "i4.g2-prometheus-lab.campusdual.mkcampus.com",
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
                    "Name": "i4.g2-prometheus-lab.campusdual.mkcampus.com",
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [{"Value": "'$PRIVATE_IP'"}]
                }
            }
        ]
    }'

    # Install Docker
    curl -fsSL https://get.docker.com/ | sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker

    # Install Ansible
    sudo apt install -y ansible

    # Run the Ansible playbook
    cd /home/ubuntu/iX-rss-engine
    ansible-playbook -i 127.0.0.1, playbook.yml

  EOF

  depends_on = [aws_security_group.sg]
}