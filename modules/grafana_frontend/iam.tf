resource "aws_iam_role" "ec2_role_i4" {
  name = "ec2-docker-role-i4"

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

resource "aws_iam_role_policy" "ec2_policy_i4" {
  name   = "ec2-docker-policy-i4"
  role   = aws_iam_role.ec2_role_i4.id
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
      # Añadir permisos para Route 53
      {
        Action   = "route53:ChangeResourceRecordSets"
        Effect   = "Allow"
        # Resource = "arn:aws:route53:::hostedzone/Z06113313M7JJFJ9M7HM8"
        Resource = data.aws_route53_zone.my_hosted_zone.arn
      },
      {
        Action   = "route53:ListResourceRecordSets"
        Effect   = "Allow"
        # Resource = "arn:aws:route53:::hostedzone/Z06113313M7JJFJ9M7HM8"
        Resource = data.aws_route53_zone.my_hosted_zone.arn
      },
      # Add DescribeInstances permission
      {
        Action   = "ec2:DescribeInstances"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_role_i4" {
  name = "ec2-docker-instance-profile-i4"
  role = aws_iam_role.ec2_role_i4.name
}
