data "aws_route53_zone" "my_hosted_zone" {
  name = "campusdual.mkcampus.com"  # Nombre del dominio
}

data "aws_secretsmanager_secret" "my_secret" {
  name = "rss-engine-imatia" 
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
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
 