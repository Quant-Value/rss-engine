resource "aws_key_pair" "key" {
  key_name   = "my-key-ES"
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

resource "aws_instance" "elasticsearch_nodes" {
  count           = 3  # Número de instancias EC2 que deseas lanzar
  #ami             = "ami-091f18e98bc129c4e" # Ubuntu 24 ami londres
  ami             = var.ami_id
  instance_type   = "t3.large"
  subnet_id       = var.subnet_ids[(count.index % 3)]
  key_name        = aws_key_pair.key.key_name
  disable_api_stop = false
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  # Seguridad
  vpc_security_group_ids = [aws_security_group.elasticsearch.id,data.aws_security_group.default.id]
  root_block_device {
    volume_size = 30  # Tamaño en GB del volumen raíz (aumentado a 50 GB en este ejemplo)
    volume_type = "gp2"  # Tipo de volumen (general purpose SSD)
    delete_on_termination = true  # El volumen raíz se elimina cuando la instancia se termina
  }

  tags = {
    Name = "Grupo2-elastic-instance-es-${count.index + 1}",
    Grupo="g2",
    DNS_NAME="i${count.index}-rss-engine-demo"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Actualizar e instalar dependencias
              sudo apt-get update -y
              sudo apt-get install -y nfs-common

              # Montar EFS
              sudo mkdir -p /mnt/efs
              sudo mount -t nfs4 fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs

              # Configurar el montaje persistente en fstab para reinicios
              echo 'fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs nfs4 defaults 0 0' | sudo tee -a /etc/fstab

              # Establecer los permisos correctos en el EFS
              sudo chown -R 1000:1000 /mnt/efs/
              
              #set "/etc/rss-engine ${aws_instance.elasticsearch_nodes.id}"
              #set "/etc/rss-engine-dns-suffix ${aws_instance.elasticsearch_nodes.tags[DNS_NAME]}"

              echo "${self.id}" > /etc/rss-engine  # Guardar el ID de la instancia
              echo "${self.tags["DNS_NAME"]}" > /etc/rss-engine-dns-suffix  # Guardar el DNS_NAME en otro archivo
              
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              
              # Obtener la IP privada
              private_ip=$(hostname -I | awk '{print $1}')

              # Añadir la IP privada al registro de Route 53 (reemplazar los valores según sea necesario)
              zone_id="Z06113313M7JJFJ9M7HM8"  # ID de tu zona de Route 53
              record_name="${self.tags["DNS_NAME"]}.campusdual.mkcampus.com"  # Nombre del registro DNS
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
              sudo bash -c 'cat <<EOF > /etc/systemd/system/update-dns.service
                [Unit]
                Description=Actualizar registro DNS en Route 53 con la IP privada
                After=network.target

                [Service]
                Type=oneshot
                ExecStart=/bin/bash -c "private_ip=\$(hostname -I | awk '{print $1}'); 
                                        aws route53 change-resource-record-sets --hosted-zone-id Z06113313M7JJFJ9M7HM8
                                        --change-batch '\''{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"my-node.example.com\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"\$private_ip\"}]}}]}'\''"
                Restart=no

                [Install]
                WantedBy=multi-user.target
                EOF'

              # Habilitar el servicio para que se ejecute al iniciar la instancia
              sudo systemctl daemon-reload
              sudo systemctl enable update-dns.service
              sudo systemctl start update-dns.service


  EOF
}