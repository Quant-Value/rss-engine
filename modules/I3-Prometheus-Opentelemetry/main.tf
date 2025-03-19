provider "aws" {
  region = var.aws_region  # o la región correspondiente
}


resource "aws_key_pair" "key" {
  key_name   = "i3-key-g2"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}
data "aws_security_group" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_instance" "ec2_node" {
  count           = var.instance_count
  #ami             = "ami-091f18e98bc129c4e" # Ubuntu 24 ami londres
  ami             = var.ami_id
  instance_type   = "t3.large"
  subnet_id       = var.subnet_ids
  key_name        = aws_key_pair.key.key_name
  disable_api_stop = false
  
  # Asignar un rol a la instancia para acceder a ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_role.name
  # Seguridad
  vpc_security_group_ids = [aws_security_group.prometheus.id,data.aws_security_group.default.id]
  root_block_device {
    volume_size = 30  # Tamaño en GB del volumen raíz (aumentado a 50 GB en este ejemplo)
    volume_type = "gp2"  # Tipo de volumen (general purpose SSD)
    delete_on_termination = true  # El volumen raíz se elimina cuando la instancia se termina
  }

 user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Set hostname
    hostnamectl set-hostname i3-instance-demo.campusdual.mkcampus.com

    # Actualizar el sistema e instalar dependencias básicas
    apt-get update -y
    apt-get install -y nfs-common curl unzip

    # Instalar AWS CLI v2 (si es necesario)
    if ! command -v aws >/dev/null 2>&1; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
    fi

    # Escribir en el archivo /etc/rss-engine el ID de la instancia (i0, i1, etc)
    echo "i3" > /etc/rss-engine

    # Escribir en el archivo /etc/rss-engine-dns-suffix el ID junto con el sufijo
    echo "i3-instance-demo.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix

    # Configurar el hostname de la instancia
    hostnamectl set-hostname iX-rss-engine-demo.campusdual.mkcampus.com

    # Obtener la IP pública y la IP privada de la instancia
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    # Con AWS CLI, actualizar Route53 con los registros DNS para la instancia (público y privado)
    aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8 --change-batch '{
      "Comment": "Actualización de registros DNS para la instancia i'${count.index}'",
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "i3-rss-engine-demo.campusdual.mkcampus.com",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "'"$${PUBLIC_IP}"'"}]
          }
        },
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "private-i3-rss-engine-demo.campusdual.mkcampus.com",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "'"$${PRIVATE_IP}"'"}]
          }
        }
      ]
    }'

    # Instalar Docker usando el script oficial
    curl -fsSL https://get.docker.com/ | sh
  EOF


  tags = {
    Name = "i3-rss-engine-demo-${count.index}"
  }
}
    
  





