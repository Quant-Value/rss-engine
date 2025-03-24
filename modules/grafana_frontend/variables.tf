variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
  default = "../../my-ec2-key.pub"
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default = "ami-06e02ae7bdac6b938"
}

variable "subnet_ids" {
  type        = string
  description = "IDs de las subnets privadas"
  default = "subnet-0ea0184c208a85591"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
  default = "vpc-01c097d1d9b73fc50"
}

# variable "environment_id" {
#   type = string
#   default = "-rss-engine-demo"
# }

variable "hosted_zone" {
  type = string
  default = "Z06113313M7JJFJ9M7HM8"
}