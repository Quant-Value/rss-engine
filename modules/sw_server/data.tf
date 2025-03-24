data "aws_route53_zone" "my_hosted_zone" {
  name = "campusdual.mkcampus.com"  # Cambia este nombre por el nombre del dominio
}
data "aws_secretsmanager_secret" "my_secret" {
  name = "rss-engine-imatia"  # Cambia este nombre por el nombre de tu secreto
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