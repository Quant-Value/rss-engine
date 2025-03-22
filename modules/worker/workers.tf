
/*
resource "aws_instance" "ec2_instance_wk" {
  count= 10
  ami           = var.ami_id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "SW worker number ${count.index} stb ",
    Grupo= "g2"
  }

  # Crear un grupo de seguridad para permitir el acceso SSH
  security_groups = [aws_security_group.sg.name]

  associate_public_ip_address = true

  # Asignar un rol a la instancia para acceder a ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_role.name

  # Configurar el provisioner remote-exec
  provisioner "remote-exec" {
  inline = [
    # Actualizar el sistema y preparar la instancia
    "sudo apt-get update -y",
    
    # Instalar dependencias
    "sudo apt-get install -y unzip curl ca-certificates docker.io",

    # Instalar AWS CLI
    "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
    "unzip awscliv2.zip",
    "sudo ./aws/install",

    # Agregar el usuario 'ubuntu' al grupo 'docker' para evitar problemas con permisos
    "sudo usermod -aG docker ubuntu",

    # Verificar si la acción se realizó correctamente
    "groups ubuntu",

    # Reiniciar el servicio Docker para aplicar cambios en el grupo
    "sudo systemctl restart docker",

    # Iniciar sesión en ECR
    "aws ecr get-login-password --region eu-west-2 | sudo docker login --username AWS --password-stdin 248189943700.dkr.ecr.eu-west-2.amazonaws.com",

    # Descargar la imagen de Docker
    "sudo docker pull 248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go",

    # Sincronizar scripts desde S3
    "aws s3 sync s3://proyecto-devops-grupo-dos/scripts/cloud ./scripts",

    # Ejecutar el contenedor Docker desde el ECR
    "sudo docker run -d -v $(pwd)/scripts:/app/scripts -v ~/.aws:/.aws --cpus='1.5' 248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go -server=http://${aws_instance.ec2_instance.private_ip}:8080",

    # Crear el archivo de servicio systemd con permisos elevados
    "echo '[Unit]\nDescription=Docker Container for Worker\nAfter=network.target\n\n[Service]\nExecStartPre=/usr/bin/docker pull 248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go\nExecStart=/usr/bin/docker run -d -v $(pwd)/scripts:/app/scripts -v ~/.aws:/.aws --cpus=\"1.5\" 248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go -server=http://${aws_instance.ec2_instance.private_ip}:8080\nExecStop=/usr/bin/docker stop $(/usr/bin/docker ps -q --filter ancestor=248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go)\nExecStopPost=/usr/bin/docker rm $(/usr/bin/docker ps -aq --filter ancestor=248189943700.dkr.ecr.eu-west-2.amazonaws.com/stb-my-ecr-repo:worker-go)\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/myworkerapp-${count.index}.service",

    # Recargar los servicios systemd
    "sudo systemctl daemon-reload",

    # Habilitar el servicio para el arranque
    "sudo systemctl enable myworkerapp-${count.index}.service",

    # Iniciar el servicio
    "sudo systemctl start myworkerapp-${count.index}.service"
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}

}

resource "null_resource" "update_scripts_workers" {
  for_each = { for idx, ip in aws_instance.ec2_instance_wk : idx => ip.public_ip }

  provisioner "remote-exec" {
    inline = [
      "aws s3 sync s3://proyecto-devops-grupo-dos/scripts/cloud ./scripts",
      "container_id=$(sudo docker ps -lq)",
      "sudo docker exec $container_id chmod +x /app/scripts/job.sh && sudo docker exec $container_id chmod +x /app/scripts/upload.sh && sudo docker exec $container_id chmod +x /app/scripts/process_rss.sh "
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = each.value  # Usamos `each.value` para referirnos a cada IP pública
    }
  }

  triggers = {
    always_run = "${timestamp()}"  # Forzar la ejecución con un valor que cambie constantemente
  }
  depends_on=[aws_instance.ec2_instance_wk]
}
*/
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


resource "aws_instance" "ec2_instance_wk" {#hay que especificar subnet porque no puedes directamente vpc y si no se crea en la vpc default
  count           = 3
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

  user_data = templatefile("${path.module}/user_data_server.tpl", {
    instance_id = "i${count.index + 5}-${var.environment}"
    record_name = "i${count.index + 5}-${var.environment}-rss-engine-demo.campusdual.mkcampus.com" 
    zone=data.aws_route53_zone.my_hosted_zone.id
  })

  # Aquí no necesitamos provisioner "remote-exec", sino que usaremos Ansible
  depends_on = [ aws_security_group.sg ]
  #depends_on = [aws_security_group.sg,aws_instance.ec2_instance]
}



