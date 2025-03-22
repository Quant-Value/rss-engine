output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_instance_i8.public_ip
}

/*
output "ec2_instance_wk_public_ips" {
  value = aws_instance.ec2_instance_wk[*].public_ip
}

output "ec2_instance_wk_private_ips" {
  value = aws_instance.ec2_instance_wk[*].private_ip
}
*/
