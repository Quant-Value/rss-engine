# Grafana Deployment Module

This module automates the deployment of a Grafana instance on an AWS EC2 instance, configured for use with the i4-rss-engine. It sets up the necessary infrastructure, including the EC2 instance, IAM roles, security groups, and Docker, and configures Grafana to persist data on an EFS volume.  It also configures DNS records using Route53.

## Features

  * **EC2 Instance Deployment:** Provisions an EC2 instance to host the Grafana server.
  * **IAM Role and Policy:** Creates an IAM role with the necessary permissions for the EC2 instance to access other AWS services, such as ECR, S3, Route 53, and Secrets Manager.
  * **Security Group Configuration:** Configures a security group to allow SSH and Grafana (port 3000) access.
  * **EFS Integration:** Mounts an Amazon EFS volume to the EC2 instance for persistent Grafana data storage.
  * **Docker Installation:** Installs and configures Docker on the EC2 instance.
  * **Grafana Deployment:** Deploys Grafana using Docker Compose, with configurations for data persistence and a Prometheus datasource.
  * **Route 53 Integration**:  Creates or updates a DNS A record in Route 53, pointing to the public IP of the EC2 instance.  This allows for accessing the Grafana instance using a hostname.
  * **Automatic DNS Update:** Sets up a systemd service to automatically update the Route 53 DNS record whenever the EC2 instance restarts and its public IP address changes.
  * **Secrets Management:** Retrieves the Grafana admin password from AWS Secrets Manager.

## Architecture

The architecture consists of:

  * An EC2 instance running Ubuntu.
  * An EFS volume mounted to the EC2 instance for persistent storage.
  * A Security Group allowing access to the EC2 instance.
  * IAM Role and Instance Profile.
  * Route 53 for DNS management.
  * Docker and Docker Compose.
  * Grafana.
  * AWS Secrets Manager

## Prerequisites

Before using this module, ensure you have the following:

  * An AWS account.
  * An existing VPC, Subnets, and Security Groups.
  * A registered domain and a Hosted Zone in Route 53.
  * An SSH key pair for accessing the EC2 instance.
  * The AMI ID for the EC2 instance.
  * The ARN of the hosted zone.
  * The ID of the hosted zone.
  * The ARN of the AWS Secret containing the Grafana admin password.
  * The DNS name of the EFS volume.

## Getting Started

### Use


  **Define variables:**
    Create a `terraform.tfvars` file or set the following variables in your Terraform configuration:

  **How to call the module:**
  ```terraform
  module "grafana" {
    source = "../modules/grafana_frontend"
  
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
    aws_secret_arn = aws_secretsmanager_secret.rss_engine_imatia.arn
    depends_on=[aws_efs_mount_target.this]
    sg_default_id=data.aws_security_group.default.id
    efs_id=var.efs_dns_name

    aws_key_name=aws_key_pair.key_ec2.key_name
}
```


## Inputs

| Name                 | Description                                                                                                  | Type           | Default                | Required |
| -------------------- | ------------------------------------------------------------------------------------------------------------ | -------------- | ---------------------- | -------- |
| `ami_id`             | The AMI ID to use for the EC2 instance.                                                                      | `string`       | n/a                    | Yes      |
| `aws_secret_arn`     | ARN of the AWS Secrets Manager secret containing the Grafana admin password.                                    | `string`       | n/a                    | Yes      |
| `environment`        | Environment (e.g., `dev`, `prod`).                                                                           | `string`       | n/a                    | Yes      |
| `efs_id`             | The DNS name of the EFS volume.                                                                                | `string`       | n/a                    | Yes      |
| `hosted_zone_arn`    | ARN of the Route 53 Hosted Zone.                                                                               | `string`       | n/a                    | Yes      |
| `hosted_zone_id`     | ID of the Route 53 Hosted Zone.                                                                                | `string`       | n/a                    | Yes      |
| `num_availability_zones`| Number of Availability Zones to use.                                                                         | `number`       | n/a                    | No       |
| `public_key_path`    | Path to the SSH public key file associated with the private key for accessing the EC2 instances.               | `string`       | `../../my-ec2-key.pub` | No       |
| `sg_default_id`      | Security Group  to assign to the instance                                                                       | `string`       | n/a                    | Yes      |
| `subnet_ids`         | List of IDs of the subnets where the EC2 instance will be launched.                                            | `list(string)` | n/a                    | Yes      |
| `vpc_id`             | ID of the VPC where the EC2 instance will be launched.                                                           | `string`       | n/a                    | Yes      |
| `hosted_zone`        | The name of the hosted zone.                                                                                 | `string`       | n/a                    | Yes      |

## Outputs

| Name                 | Description                               |
| -------------------- | ----------------------------------------- |
| `instance_public_ip` | The public IP address of the EC2 instance. |
| `instance_private_ip`| The private IP address of the EC2 instance. |
| `sg_id`              | The ID of the security group created.     |

## User Data

The `user_data.tpl` template configures the EC2 instance on startup.  Here's a breakdown of the actions performed:

  * System updates and dependency installation (unzip, curl, nfs-common, git, python3-pip).
  * Hostname configuration.
  * EFS volume mounting and persistent mount configuration via `/etc/fstab`.
  * AWS CLI installation.
  * Docker installation and startup.
  * Adds the `ubuntu` user to the `docker` group.
  * Retrieves the instance ID and public IP.
  * Configures a Route 53 A record with the instance's public IP.
  * Creates a systemd service (`update-dns.service`) to keep the Route 53 record updated on reboot.
  * Clones the Grafana Docker Compose file from GitHub.
  * Retrieves the Grafana admin password from AWS Secrets Manager.
  * Configures Grafana's `custom.ini` with the admin password.
  * Configures the Prometheus datasource for Grafana.
  * Starts Grafana using Docker Compose.

## IAM Permissions

The module creates an IAM role (`ec2-docker-role-i4`) and policy (`ec2-docker-policy-i4`) with the following permissions:

  * `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`:  For pulling Docker images from ECR.
  * `s3:*`:  For access to S3 buckets.
  * `route53:ChangeResourceRecordSets`, `route53:ListResourceRecordSets`: For managing DNS records in Route 53.
  * `ec2:DescribeInstances`: For retrieving EC2 instance information.
  * `secretsmanager:GetSecretValue`: For retrieving the Grafana admin password from AWS Secrets Manager.

## Security

  * The module creates a security group (`i4-ec2-security-group`) that allows SSH access (port 22) and Grafana access (port 3000) from any IP address (`0.0.0.0/0`).  **It is highly recommended to restrict access to specific IP addresses or CIDR blocks in a production environment.**
  * The Grafana admin password is retrieved from AWS Secrets Manager, enhancing security.
  * EFS volume is mounted with specific user and group ownership (1000:1000).

## DNS Configuration

The module uses Route 53 to manage DNS records. It creates or updates an A record for the EC2 instance, mapping a hostname (e.g., `i4-dev-rss-engine-demo.campusdual.mkcampus.com`) to the instance's public IP address.  A systemd service is also configured to update this record automatically on instance restarts.

## Docker Compose

The module uses a `docker-compose.yml` file to deploy Grafana.  The Docker Compose configuration:

  * Uses the `grafana/grafana:11.5.2-ubuntu` image.
  * Mounts the EFS volume to `/grafana` for persistent data storage.
  * Mounts the `custom.ini` configuration file to `/config`.
  * Mounts the Prometheus datasource configuration to `/etc/grafana/provisioning/datasources`.
  * Exposes port 3000 for accessing the Grafana web interface.
  * Sets the `GF_PATHS_CONFIG` environment variable to point to the custom configuration file.















