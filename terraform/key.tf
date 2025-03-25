resource "aws_key_pair" "key_ec2" {
  key_name   = "key-rss-imatia-${var.environment}"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}