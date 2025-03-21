provider "aws" {
  region = "eu-west-3"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "i8-key-g2"
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
    DNS_NAME="i8-rss-engine-demo"

  }

  # Crear un grupo de seguridad para permitir el acceso SSH
  vpc_security_group_ids = [aws_security_group.sg.id]

  associate_public_ip_address = true

  # Asignar un rol a la instancia para acceder a ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_role.name
  
    user_data = templatefile("${path.module}/user_data_server.tpl", {
    instance_id = "i8-${var.environment}"
    record_name = "i8-${var.environment}-rss-engine-demo.campusdual.mkcampus.com" 
    zone=data.aws_route53_zone.my_hosted_zone.id
  })

  depends_on = [aws_security_group.sg]
}



