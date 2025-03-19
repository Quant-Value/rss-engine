#!/bin/bash
set -ex

# ================================
# CONFIGURACIÓN DE VARIABLES
# ================================

# Define el identificador de la instancia (modifícalo según corresponda: "i3", "i0", etc.)
INSTANCE_INDEX="i3"

# Define la Hosted Zone de Route53 donde se actualizarán los registros
HOSTED_ZONE_ID="Z06113313M7JJFJ9M7HM8"

# -------------------------------
# CONFIGURAR CREDENCIALES DEL AWS CLI
# -------------------------------
# Reemplaza los valores entre comillas con tu AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY.
# ¡ADVERTENCIA! No almacenes credenciales en texto plano en producción.
aws configure set aws_access_key_id ""
aws configure set aws_secret_access_key ""
aws configure set default.region "eu-west-3"

# Alternativamente, también puedes exportar las variables de entorno:
# export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
# export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
# export AWS_DEFAULT_REGION="eu-west-3"

# ================================
# ACTUALIZAR SISTEMA E INSTALAR DEPENDENCIAS
# ================================
sudo apt-get update -y
sudo apt-get install -y nfs-common curl unzip

# ================================
# INSTALAR AWS CLI V2 (si no está instalado)
# ================================
if ! command -v aws >/dev/null 2>&1; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
fi

# ================================
# CONFIGURAR ARCHIVOS Y HOSTNAME
# ================================
# Escribir el identificador en /etc/rss-engine
echo "$INSTANCE_INDEX" | sudo tee /etc/rss-engine

# Escribir el DNS suffix en /etc/rss-engine-dns-suffix
DNS_SUFFIX="${INSTANCE_INDEX}-instance-demo.campusdual.mkcampus.com"
echo "$DNS_SUFFIX" | sudo tee /etc/rss-engine-dns-suffix

# Configurar el hostname deseado (por ejemplo: "i3-rss-engine-demo.campusdual.mkcampus.com")
HOSTNAME="${INSTANCE_INDEX}-rss-engine-demo.campusdual.mkcampus.com"
sudo hostnamectl set-hostname "$HOSTNAME"

# ================================
# OBTENER IP PÚBLICA Y PRIVADA (USANDO IMDSv2)
# ================================
# Solicitar el token para IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
          -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Obtener la IP pública y privada usando el token
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
             http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
              http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"

# ================================
# ACTUALIZAR REGISTROS DNS EN ROUTE53
# ================================
ROUTE53_PAYLOAD=$(cat <<EOF
{
  "Comment": "Actualización de registros DNS para la instancia ${INSTANCE_INDEX}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${HOSTNAME}",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          { "Value": "${PUBLIC_IP}" }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "private-${HOSTNAME}",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          { "Value": "${PRIVATE_IP}" }
        ]
      }
    }
  ]
}
EOF
)

# Mostrar el payload para verificar
echo "$ROUTE53_PAYLOAD"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "$ROUTE53_PAYLOAD"

# ================================
# INSTALAR DOCKER (USANDO EL SCRIPT OFICIAL)
# ================================
curl -fsSL https://get.docker.com/ | sh

