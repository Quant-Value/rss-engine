variable "public_key_path" {
  description = "Ruta al archivo de la clave pública SSH asociada a la clave privada para acceder a las instancias EC2."
  type        = string
  default = "../../my-ec2-key.pub"
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

# variable "environment_id" {
#   type = string
#   default = "-rss-engine-demo"
# }

variable "hosted_zone" {
  type = string
}

variable "num_availability_zones" {
  type        = number

}

variable "hosted_zone_arn" {
  type        = string
  description = "route53 hostez zone arn"

}
variable "hosted_zone_id" {
  type        = string
  description = "route53 hostez zone arn"

}
variable "amount"{
  type=number
  default=3
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
}

variable "aws_secret_arn" {
  type        = string
  description = "arn from secret"

}

variable "efs_id"{
  type=string
}