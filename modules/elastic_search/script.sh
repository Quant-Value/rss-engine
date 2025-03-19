#!/bin/bash
# Actualizar e instalar dependencias
sudo apt-get update -y
sudo apt-get install -y nfs-common unzip 

# Montar EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs

# Configurar el montaje persistente en fstab para reinicios
echo 'fs-09f3adbae659e7e88.efs.eu-west-3.amazonaws.com:/ /mnt/efs nfs4 defaults 0 0' | sudo tee -a /etc/fstab

# Establecer los permisos correctos en el EFS
sudo chown -R 1000:1000 /mnt/efs/
              
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


    #echo "${aws_instance.elasticsearch_nodes[0].id}" > /etc/rss-engine  # Guardar el ID de la instancia
    #echo "${aws_instance.elasticsearch_nodes[0].tags["DNS_NAME"]}" > /etc/rss-engine-dns-suffix  # Guardar el DNS_NAME en otro archivo