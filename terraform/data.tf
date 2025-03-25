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


data "aws_route53_zone" "my_hosted_zone" {
  name = "campusdual.mkcampus.com"  # Cambia este nombre por el nombre del dominio
}


data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]  # La VPC ID donde buscar las subnets
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]  # Asegura que las subnets no asignen IP pública a las instancias
  }
}

data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]  # La VPC ID donde buscar las subnets
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]  # Asegura que las subnets asignen IP pública a las instancias
  }
}

data "aws_availability_zones" "available" {
  state = "available"  # Solo obtener las zonas de disponibilidad activas
}

locals {
  num_availability_zones = length(data.aws_availability_zones.available.names) 
}

