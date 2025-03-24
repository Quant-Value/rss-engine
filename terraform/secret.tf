
resource "random_password" "example" {
  length  = 22               # Longitud de la contraseña
  special = false              # Incluir caracteres especiales como !, @, #, etc.
  upper   = true              # Incluir letras mayúsculas
  lower   = true              # Incluir letras minúsculas
  numeric  = true              # Incluir números
}
/*
output "random_password" {
  value = random_password.example.result
}
*/
data "aws_secretsmanager_secret" "rss_engine_imatia" {
  name = "rss-engine-imatia"
}
# Crear el secreto solo si no existe
resource "aws_secretsmanager_secret" "rss_engine_imatia" {
  count       = length(data.aws_secretsmanager_secret.rss_engine_imatia.id) == 0 ? 1 : 0
  name        = "rss-engine-imatia"
  description = "Secreto para RSS Engine con elasticpass generado aleatoriamente"
  
  tags = {
    Name = "RSS Engine Imatia Secret"
  }
}

# Crear la versión del secreto con el par clave-valor
resource "aws_secretsmanager_secret_version" "rss_engine_imatia_version" {
  secret_id     = length(data.aws_secretsmanager_secret.rss_engine_imatia.id) == 0 ? aws_secretsmanager_secret.rss_engine_imatia[0].id : data.aws_secretsmanager_secret.rss_engine_imatia.id
  secret_string = jsonencode({
    elasticpass = random_password.example.result
  })
  depends_on = [aws_secretsmanager_secret.rss_engine_imatia]
}


