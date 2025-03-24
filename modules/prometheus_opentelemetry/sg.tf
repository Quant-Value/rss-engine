### 6. Security Groups
resource "aws_security_group" "prometheus" {
  name        = "${var.project_name}-${var.environment}-es-sg"
  description = "SG for Elasticsearch"
  vpc_id      = var.vpc_id





  ingress {
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }


      ingress {
    from_port   = 8889
    to_port     = 8889
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #security_groups = [aws_security_group.elasticsearch_alb.id]
    cidr_blocks = [data.aws_vpc.default.cidr_block]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-es-sg",
    Grupo="g2"
  }
}




