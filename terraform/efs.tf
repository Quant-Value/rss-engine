
resource "aws_efs_file_system" "this" {
  creation_token   = "efs-${var.environment}"
  performance_mode = "generalPurpose"
  encrypted        = true

  tags = {
    Grupo="g2",
    Name="efs-demo"
  }

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_efs_mount_target" "this" {
  for_each = toset(data.aws_subnets.public_subnets.ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [data.aws_security_group.default.id]

  lifecycle {
    prevent_destroy = false
  }

}
