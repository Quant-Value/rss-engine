variable "region" {
  description = "AWS region"
  type=string

}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}


variable "public_key_path" {
  description = "The public SSH key to use for the EC2 instance"
  type        = string
}
variable "private_key_path" {
  description = "The public SSH key to use for the EC2 instance"
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