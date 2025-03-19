resource "aws_iam_role" "ec2_role" {
  name = "ec2-docker-role-i3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name   = "ec2-docker-policy-i3"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ecr:GetAuthorizationToken"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "ecr:BatchCheckLayerAvailability"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "ecr:GetDownloadUrlForLayer"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "ecr:BatchGetImage"  # Añadido permiso para obtener las imágenes
        Effect   = "Allow"
        Resource = "*"
      },
      # Permisos completos sobre S3
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "ec2-docker-instance-profile-i3"
  role = aws_iam_role.ec2_role.name
}