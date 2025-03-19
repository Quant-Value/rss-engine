variable "aws_region" {
  type        = string
  description = "Región de AWS"
  default     = "eu-west-3"
}



variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
  default     = "simple-worker-g2-i3"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
  default = "vpc-01c097d1d9b73fc50"
}

variable "subnet_ids" {
  type        = string
  description = "IDs de las subnets privadas"
  default = "subnet-0ea0184c208a85591"
}
variable "instance_count" {
  description = "Cantidad de instancias a crear"
  type        = number
  default     = 1
}



variable "volume_size" {
  type        = number
  description = "Tamaño del volumen EBS en GB"
  default     = 100
}
variable "private_key_path" {
  description = "Ruta al archivo de la clave privada SSH para acceder a las instancias EC2."
  type        = string
  default = "/home/jorge/Documentos/Bootcamp/Grupo/Prometheus_lab/my-ec2-key"
}

variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
  default = "/home/jorge/Documentos/Bootcamp/Grupo/Prometheus_lab/my-ec2-key.pub"
}



variable "performance_mode" {
  description = "Modo de rendimiento del sistema de archivos EFS"
  type        = string
  default     = "generalPurpose"
}

variable "encrypted" {
  description = "Indica si el sistema de archivos EFS está encriptado"
  type        = bool
  default     = true
}
variable "tags" {
  description = "Mapa de etiquetas a asignar al sistema de archivos EFS"
  type        = map(string)
  default     = {}
}
variable "ami_id" {
  type        = string
  default = "ami-06e02ae7bdac6b938"
}