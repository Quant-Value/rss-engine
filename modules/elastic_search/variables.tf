variable "aws_region" {
  type        = string
  description = "Región de AWS"
  #default     = "eu-west-2"
}


# ID de la VPC (para la consulta de seguridad)
variable "vpc_id" {
  description = "ID de la VPC donde se encuentran las instancias"
  type        = string
  #default     = "vpc-01c097d1d9b73fc50"  # Reemplaza con el ID de tu VPC
}
variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"

}

variable "private_key_path" {
  description = "Ruta al archivo de la clave privada SSH para acceder a las instancias EC2."
  type        = string
  #default = "../../my-ec2-key"
}

variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
  #default = "../../my-ec2-key.pub"
}

# ID de la AMI (Imagen de la máquina virtual)
variable "ami_id" {
  description = "ID de la imagen de la máquina virtual"
  type        = string
  default     = "ami-06e02ae7bdac6b938"  # Reemplaza con el ID de tu AMI
}


variable "environment"{
    type= string
    #default= "demo"
}
variable "amount"{
  type=number
  default=3
}

variable "sg_sw_worker"{
    type= string
}

