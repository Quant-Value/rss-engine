
variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"
}

variable "volume_size" {
  type        = number
  description = "Tamaño del volumen EBS en GB"
  default     = 100
}
variable "private_key_path" {
  description = "Ruta al archivo de la clave privada SSH para acceder a las instancias EC2."
  type        = string
}

variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
}


variable "tags" {
  description = "Mapa de etiquetas a asignar al sistema de archivos EFS"
  type        = map(string)
  default     = {}
}
variable "ami_id" {
  type        = string
}


variable "hosted_zone_id" {
  description = "Hosted Zone ID de Route53 donde se actualizarán los registros DNS"
  type        = string
}

variable "hosted_zone_arn" {
  description = "Hosted Zone ID de Route53 donde se actualizarán los registros DNS"
  type        = string
}

variable "efs_id"{
  type=string
}

variable "sg_default_id"{
  type=string
}

variable "sg_wk" {
  type = string
}

variable "sg_grafana" {
  type = string
}
variable "aws_key_name"{
  type = string
}