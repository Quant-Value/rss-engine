provider "aws" {
  region = "eu-west-3"
}

resource "aws_key_pair" "key" {
  key_name   = "my-ec2-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "public_ec2" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.key.key_name
  subnet_id       = var.subnet_ids
  disable_api_stop = false

  tags = {
    Name = "I4_instance",
    Grupo= "g2"

  }
  iam_instance_profile = aws_iam_instance_profile.ec2_role_i4.name

  # Crear un grupo de seguridad para permitir el acceso SSH
  vpc_security_group_ids = [aws_security_group.sg.id]

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.tpl", {
    instance_id = "-rss-engine-demo"
  })

  depends_on = [aws_security_group.sg]
}