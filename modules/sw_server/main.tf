

resource "aws_instance" "ec2_instance_i8" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = var.aws_key_name
  subnet_id       = var.subnet_ids[0]
  disable_api_stop = false

  tags = {
    Name = "i8 SW server Grupo2-${var.environment}",
    Grupo= "g2",
    DNS_NAME="i8-rss-engine-demo"

  }

  # Crear un grupo de seguridad para permitir el acceso SSH
  vpc_security_group_ids = [aws_security_group.sg_server.id]

  associate_public_ip_address = true

  # Asignar un rol a la instancia para acceder a ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_role_i8.name
  
    user_data = templatefile("${path.module}/user_data.tpl", {
    instance_id = "i8-${var.environment}"
    record_name = "i8-${var.environment}-rss-engine-demo.campusdual.mkcampus.com" 
    zone=var.hosted_zone_id
    secret_name=var.secret_name
  })

  depends_on = [aws_security_group.sg_server]
}
locals {
  record_name = "i8-${var.environment}-rss-engine-demo.campusdual.mkcampus.com" 
}



