# ID de la VPC (para la consulta de seguridad)
variable "vpc_id" {
  description = "ID de la VPC donde se encuentran las instancias"
  type        = string
  default     = "vpc-01c097d1d9b73fc50"  # Reemplaza con el ID de tu VPC
}

# Ruta a la clave pública SSH
variable "public_key_path" {
  description = "Ruta de la clave pública SSH"
  type        = string
  default     = "../../my-ec2-key.pub"  # Ruta predeterminada de la clave pública
}

# ID de la AMI (Imagen de la máquina virtual)
variable "ami_id" {
  description = "ID de la imagen de la máquina virtual"
  type        = string
  default     = "ami-06e02ae7bdac6b938"  # Reemplaza con el ID de tu AMI
}

# Subredes disponibles para las instancias EC2
variable "subnet_ids" {
  description = "Lista de IDs de subredes disponibles"
  type        = list(string)
  default     = ["subnet-03212edf6d0f0c101", "subnet-00ba1197ad5eb3854", "subnet-0d5acc6337a4f307d"]  # Reemplaza con los IDs de tus subredes
}
variable "environment"{
    type= string
    default= "demo"
}

