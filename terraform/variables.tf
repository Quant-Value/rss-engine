variable "aws_region" {
  type        = string
  description = "Región de AWS"
  #default     = "eu-west-2"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
   #default= "vpc-01c097d1d9b73fc50"
}


variable "private_key_path" {
  description = "Ruta al archivo de la clave privada SSH para acceder a las instancias EC2."
  type        = string
}

variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
}
variable "secret_name"{
  type=string
}
variable "efs_dns_name"{
  type=string
}