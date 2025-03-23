
provider "aws" {
  region = var.aws_region  # o la región correspondiente
}

resource "aws_key_pair" "key" {
  key_name   = "i5-key-g2"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}

resource "random_integer" "example" {
  min = 1   # The minimum value (inclusive)
  max = 100 # The maximum value (inclusive)
}

locals{ # cambiar esto por un output
  sw_server_dns_name="i8-demo-rss-engine-demo.campusdual.mkcampus.com"
}
resource "aws_instance" "ec2_instance_wk" {#hay que especificar subnet porque no puedes directamente vpc y si no se crea en la vpc default
  count           = var.amount
  ami             = var.ami_id
  instance_type   = "t2.micro"
  subnet_id       = var.subnet_ids[((random_integer.example.result+count.index)%3)]
  key_name        = aws_key_pair.key.key_name
  disable_api_stop = false

  tags = {
    Name  = "SW worker i${count.index + 5} Grupo2"
    Grupo = "g2"
    DNS_NAME="i${count.index + 5}-rss-engine-demo"
  }

  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_role_i5.name

  user_data = templatefile("${path.module}/user_data.tpl", {
    instance_id = "i${count.index + 5}-${var.environment}"
    record_name = "i${count.index + 5}-${var.environment}-rss-engine-demo.campusdual.mkcampus.com" 
    zone=data.aws_route53_zone.my_hosted_zone.id
    sw_server_dns_name=local.sw_server_dns_name #cambiar esto por un output
  })

  # Aquí no necesitamos provisioner "remote-exec", sino que usaremos Ansible
  depends_on = [ aws_security_group.sg ]

}



