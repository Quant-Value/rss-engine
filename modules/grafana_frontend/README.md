# Grafana Terraform Module

This Terraform module automates the creation of a Grafana instance on AWS. It creates an EC2 instance, configures the necessary IAM resources, and deploys Grafana using Docker.

## Description

The module performs the following actions:

* **Provision an EC2 instance**: Creates an EC2 instance on AWS to host Grafana.
* **Configure IAM**: Creates an IAM role and instance profile with the necessary permissions for Grafana to interact with other AWS services.
* **Deploy Grafana with Docker**: Uses Docker to deploy Grafana on the EC2 instance.
* **Configure Route 53 (optional)**: Updates a Route 53 DNS record to point to the Grafana instance.
* **Mount an EFS volume (optional)**: Mounts an Elastic File System (EFS) volume for persistent storage of Grafana data.

## Usage

To use this module, you need to have Terraform installed and configured with your AWS credentials. You can then declare the module in your Terraform configuration and provide the required values.

Here's an example of how to use this module to deploy Grafana:

```terraform
module "grafana" {
    source = "./modules/grafana_frontend"
    
    vpc_id = var.vpc_id
    public_key_path= var.public_key_path

    amount= 3

    ami_id = data.aws_ami.ubuntu_latest.id
    subnet_ids = data.aws_subnets.public_subnets.ids
    hosted_zone = data.aws_route53_zone.my_hosted_zone.id
    num_availability_zones = local.num_availability_zones
    hosted_zone_arn = data.aws_route53_zone.my_hosted_zone.arn
    hosted_zone_id = data.aws_route53_zone.my_hosted_zone.id
    environment = var.environment
    aws_secret_arn = data.aws_secretsmanager_secret.my_secret.arn
    depends_on=[aws_efs_mount_target.this]
    sg_default_id=data.aws_security_group.default.id
    efs_id=aws_efs_file_system.this.dns_name
}
```

## Variables

The module defines the following variables:

|  | **Name** | **Description** | **Type** | **Default** | **Required** |
| --- | --- | --- | --- | --- | --- |
|  | `ami_id` | The ID of the Amazon Machine Image (AMI) to use for the EC2 instance. | `string` | N/A | Yes |
|  | `subnet_ids` | A list of subnet IDs where the EC2 instance will be launched. | `list(string)` | N/A | Yes |
|  | `environment` | The environment in which Grafana will be deployed (e.g., production, staging, development). Used for resource tagging. | `string` | N/A | Yes |
|  | `region` | The AWS region where resources will be created. | `string` | N/A | Yes |
|  | `hosted_zone_id` | (Optional) The ID of the Route 53 hosted zone where the DNS record will be created. If provided, the module will create an A record pointing to the EC2 instance. | `string` | `""` | No |
|  | `efs_id` | (Optional) The ID of the Elastic File System (EFS) file system to mount on the EC2 instance for persistent data storage. | `string` | `""` | No |
|  | `public_key_path` | (Optional) The path to the SSH public key to use for accessing the EC2 instance. | `string` | `~/.ssh/id_rsa.pub` | No |
|  | `sg_default_id` | (Optional) The ID of the default security group for the VPC. | `string` | `""` | No |
|  | `aws_secret_arn` | (Optional) The ARN of the AWS Secrets Manager secret containing the ElasticSearch credentials. | `string` | `""` | No |

## Outputs

The module defines the following outputs:

|  | **Name** | **Description** |
| --- | --- | --- |
|  | `instance_public_ip` | The public IP address of the Grafana EC2 instance. |
|  | `instance_private_ip` | The private IP address of the Grafana EC2 instance. |
|  | `sg_id` | The ID of the security group created for the Grafana instance. |

## Dependencies

* Terraform
* AWS provider for Terraform







