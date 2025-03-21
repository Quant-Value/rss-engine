output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}
  output "instance_private_ip" {
    value = aws_instance.ec2_instance.private_ip
  }
output "ec2_instance_wk_public_ips" {
  value = aws_instance.ec2_instance_wk[*].public_ip
}

output "ec2_instance_wk_private_ips" {
  value = aws_instance.ec2_instance_wk[*].private_ip
}