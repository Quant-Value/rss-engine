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

variable "instance_index" {
  description = "Identificador de la instancia (por ejemplo, 'i3', 'i0', etc.)"
  type        = string
  default     = "i3"
}

variable "hosted_zone_id" {
  description = "Hosted Zone ID de Route53 donde se actualizarán los registros DNS"
  type        = string
  default     = "Z06113313M7JJFJ9M7HM8"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID para configurar AWS CLI (usar solo en entornos de prueba)"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key para configurar AWS CLI (usar solo en entornos de prueba)"
  type        = string
  sensitive   = true
}