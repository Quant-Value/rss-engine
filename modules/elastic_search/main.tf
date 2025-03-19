
provider "aws" {
  region = "eu-west-3"
}

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
  ami             = var.ami_id
  instance_type   = "t3.large"
  subnet_id       = var.subnet_ids[(count.index % 3)]
  key_name        = aws_key_pair.key.key_name
  disable_api_stop = false

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
    sudo apt-get update -y
    sudo apt-get install -y nfs-common unzip dos2unix
    echo "i${count.index}" > /etc/rss-engine  # Guardar el ID de la instancia
    echo "-rss-engine-demo.campusdual.mkcampus.com" > /etc/rss-engine-dns-suffix  # Guardar el DNS_NAME en otro archivo
    curl 
  EOF
}