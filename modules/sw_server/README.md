# AWS SW Server Deployment Module

This Terraform module automates the deployment of an SW Server on an AWS EC2 instance. It configures the necessary infrastructure, including EC2 instance provisioning, IAM roles, security groups, and Docker Compose setup. It also integrates with Route 53 for DNS management.

## Features

* **EC2 Instance Provisioning:** Deploys a single EC2 instance with specified configurations.
* **IAM Role and Policy:** Creates an IAM role with required permissions for ECR, S3, Route 53, and Secrets Manager access.
* **Security Group Configuration:** Configures a security group to allow SSH access, application port (8080), and ICMP traffic.
* **Docker Compose Deployment:** Sets up and runs Docker containers using a provided `docker-compose.yml` file.
* **Route 53 DNS Management:** Automatically updates a Route 53 A record with the instance's public IP.
* **Automatic DNS Update on Reboot:** Configures a systemd service to update the DNS record on instance restarts.
* **Secrets Management:** Retrieves sensitive data from AWS Secrets Manager.

## Architecture

The architecture consists of:

* A single EC2 instance running a specified AMI.
* An IAM role with necessary permissions.
* A security group allowing required network traffic.
* Docker Compose for container management.
* Route 53 for DNS management.
* AWS Secrets Manager for secure secret retrieval.

## Prerequisites

Before using this module, ensure you have the following:

* An AWS account with appropriate permissions.
* An existing VPC and subnet.
* A registered domain and hosted zone in Route 53.
* An SSH key pair for EC2 instance access.
* The AMI ID for the EC2 instance.
* The ARN and ID of the Route 53 hosted zone.
* The ARN of the AWS Secrets Manager secret.

## Getting Started

### Usage

To use this module, define the required variables in your Terraform configuration and then apply the module.

## Module Invocation

Para invocar este módulo en tu configuración de Terraform, utiliza el siguiente bloque de código:

```terraform
module "sw_server" {
  source = "../modules/sw_server"

  vpc_id          = var.vpc_id
  aws_region      = var.aws_region
  private_key_path = var.private_key_path
  public_key_path  = var.public_key_path
  environment     = var.environment

  subnet_ids      = data.aws_subnets.public_subnets.ids
  hosted_zone_arn = data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id  = data.aws_route53_zone.my_hosted_zone.id
  aws_secret_arn  = data.aws_secretsmanager_secret.rss_engine_imatia.arn
  ami_id          = data.aws_ami.ubuntu_latest.id

  aws_key_name    = aws_key_pair.key_ec2.key_name
}
``` 
## Inputs

| Name             | Description                                                                 | Type        | Default                | Required |
| :--------------- | :-------------------------------------------------------------------------- | :---------- | :--------------------- | :------- |
| `aws_region`     | AWS region for deployment.                                                   | `string`    | n/a                    | Yes      |
| `ami_id`         | The AMI ID to use for the EC2 instance.                                      | `string`    | n/a                    | No       |
| `private_key_path`| Path to the SSH private key file.                                            | `string`    | n/a                    | No       |
| `public_key_path` | Path to the SSH public key file.                                             | `string`    | n/a                    | No       |
| `vpc_id`         | ID of the VPC.                                                               | `string`    | n/a                    | Yes      |
| `environment`    | Environment (dev/prod).                                                     | `string`    | n/a                    | Yes      |
| `subnet_ids`     | List of subnet IDs.                                                          | `list(string)`| n/a                    | Yes      |
| `hosted_zone_arn`| ARN of the Route 53 hosted zone.                                             | `string`    | n/a                    | Yes      |
| `hosted_zone_id` | ID of the Route 53 hosted zone.                                              | `string`    | n/a                    | Yes      |
| `aws_secret_arn` | ARN of the AWS Secrets Manager secret.                                       | `string`    | n/a                    | Yes      |
| `aws_key_name`   | Name of the AWS key pair for SSH access.                                     | `string`    | n/a                    | Yes      |

## Outputs

| Name                 | Description                                    |
| :------------------- | :--------------------------------------------- |
| `instance_public_ip` | Public IP of the EC2 instance.                |
| `sg_id_server`       | The ID of the Security Group created.            |
| `dns_name_server`    | The DNS name of the server.                  |

## User Data (`user_data.tpl`)

The `user_data.tpl` script configures the EC2 instance on startup. It performs the following actions:

* Updates packages and installs dependencies (Docker, AWS CLI, etc.).
* Installs and configures Docker.
* Configures Route 53 DNS record with the instance's public IP.
* Sets up a systemd service to update the DNS record on reboot.
* Downloads and runs the Docker Compose file.
* Retrieves secrets from AWS Secrets Manager.
* Executes a custom grabber script.

## Docker Compose (`docker-compose-server.yml`)

* **`myserver`**: Runs the `flexvega/simple-worker:1.0.0-alpine` image as a server. It uses the host's network, restarts always, exposes port 8080, and limits CPU and memory resources.
* **`myserver_add`**: Runs the same image for additional tasks. It also uses the host's network, restarts on failure, and is configured to run indefinitely.

## IAM Permissions (`iam.tf`)

The module creates an IAM role (`ec2-docker-role-i8-<environment>`) and policy (`ec2-docker-policy-i8-<environment>`) with the following permissions:

* ECR access for Docker image retrieval.
* S3 read access.
* Route 53 permissions for DNS management.
* Secrets Manager access for secret retrieval.
* EC2 DescribeInstances permission.

## Security (`sg.tf`)

The module configures a security group (`ec2-security-group-i8-<environment>`) that allows:

* SSH access (port 22) from any IP.
* Application access (port 8080) from the instance itself.
* ICMP (ping) from any IP.
* All outbound traffic.

**Note:** It is recommended to restrict SSH access to specific IP ranges in production environments.