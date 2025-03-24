 /*
 terraform {
   backend "s3" {
     bucket  = "proyecto-devops-grupo-dos-paris"         # Nombre de tu bucket S3
     key     = "sw_server_tests/terraform.tfstate"   # Ruta y nombre del archivo de estado
     region  = "eu-west-3"                          # Región del bucket
     encrypt = true
   }
 }
*/