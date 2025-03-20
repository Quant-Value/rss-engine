### 6. Security Groups
resource "aws_security_group" "prometheus" {
  name        = "${var.project_name}-${var.environment}-es-sg"
  description = "SG for Elasticsearch"
  vpc_id      = var.vpc_id



  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Elasticsearch REST API"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Elasticsearch REST API"
  }
  
    ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Elasticsearch REST API"
  }
  
  ingress {
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = ["0.0.0.0/0"]
  }
      ingress {
    from_port   = 8889
    to_port     = 8889
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
      ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = ["0.0.0.0/0"]
  }
    # Elasticsearch internal comunication
  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"    
    self = true
  }

  # Ingress para NFS (puerto 2049) desde EC2
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #security_groups = [aws_security_group.elasticsearch_alb.id]
    cidr_blocks = ["0.0.0.0/0"]

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




