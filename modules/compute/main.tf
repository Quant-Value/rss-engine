provider "aws" {
  region = "eu-west-3"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key_sw_stb"
  public_key = file(var.public_key_path)
}


resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.key_pair.key_name
  subnet_id       = var.subnet_ids[0]
  disable_api_stop = false

  tags = {
    Name = "simple worker server Grupo2",
    Grupo= "g2",
    DNS_NAME="SW-SERVER"

  }

  # Crear un grupo de seguridad para permitir el acceso SSH
  vpc_security_group_ids = [aws_security_group.sg.id]

  associate_public_ip_address = true

  # Asignar un rol a la instancia para acceder a ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_role.name
  

  depends_on = [aws_security_group.sg]
}


resource "null_resource" "write_config_server" {
  depends_on = [aws_instance.ec2_instance]  # Asegurarse de que el ALB se haya creado antes de ejecutar esto

  provisioner "local-exec" {
    command ="echo SW_SERVER=${aws_instance.ec2_instance.public_ip} >> ../scripts/cloud/.env"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}


