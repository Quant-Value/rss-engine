

resource "aws_key_pair" "key" {
  key_name   = "my-key-ES"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}



resource "aws_instance" "elasticsearch_nodes" {
  count           = var.amount  # Número de instancias EC2 que deseas lanzar
  ami             = var.ami_id
  instance_type   = "t3.large"
  subnet_id       = var.subnet_ids[(count.index % var.num_availability_zones)]
  key_name        = aws_key_pair.key.key_name
  disable_api_stop = false

  iam_instance_profile = aws_iam_instance_profile.ec2_role_i0.name
  # Seguridad
  vpc_security_group_ids = [aws_security_group.elasticsearch.id,var.sg_default_id]
  root_block_device {
    volume_size = 30  # Tamaño en GB del volumen raíz (aumentado a 50 GB en este ejemplo)
    volume_type = "gp2"  # Tipo de volumen (general purpose SSD)
    delete_on_termination = true  # El volumen raíz se elimina cuando la instancia se termina
  }

  tags = {
    Name = "Grupo2-elastic-instance-es-${count.index + 1}",
    Grupo="g2",
    DNS_NAME="i${count.index}-rss-engine-demo"
  }

  user_data = templatefile("${path.module}/user_data.tpl", {
    instance_id = "i${count.index}-${var.environment}"  # Pasar el ID de la instancia dinámicamente
    cantidad    = var.amount  # Pasar la variable cantidad al user_data.tpl
    index = count.index
    zone=var.hosted_zone_id
    efs_id=var.efs_id
  })
}