### 6. Security Groups
resource "aws_security_group" "prometheus" {
  name        = "i3-sg-${var.environment}-es-sg"
  description = "SG for Elasticsearch"
  vpc_id      = var.vpc_id


      ingress {
    from_port   = 8889
    to_port     = 8889
    protocol    = "tcp"
    description = "Allow NFS traffic from EC2 instances"
    self = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #security_groups = [aws_security_group.elasticsearch_alb.id]
    cidr_blocks = ["0.0.0.0/0"]

  }

   ingress {
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    security_groups = [var.sg_wk]
  }

     ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    security_groups = [var.sg_grafana]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "i3-sg-${var.environment}-es-sg",
    Grupo="g2"
  }
}




