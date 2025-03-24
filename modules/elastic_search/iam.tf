resource "aws_iam_role" "ec2_role_i0" {
  name = "ec2-docker-role-i0"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
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


resource "aws_iam_role_policy" "ec2_policy_i0" {
  name   = "ec2-docker-policy-i0"
  role   = aws_iam_role.ec2_role_i0.id
  policy = jsonencode({
    Version   = "2012-10-17"
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
        Action   = "ecr:BatchGetImage"  // Permiso para obtener imágenes desde ECR
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      // Añadir permisos para Route 53
      {
        Action   = "route53:ChangeResourceRecordSets"
        Effect   = "Allow"
        Resource = var.hosted_zone_arn
      },
      {
        Action   = "route53:ListResourceRecordSets"
        Effect   = "Allow"
        Resource = var.hosted_zone_arn
      },
      {
        Action: "secretsmanager:GetSecretValue",
        Effect: "Allow",
        Resource: var.aws_secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_role_i0" {
  name = "ec2-docker-instance-profile-i0"
  role = aws_iam_role.ec2_role_i0.name
}
