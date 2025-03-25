# Elasticsearch Deployment Module

This module automates the deployment of an Elasticsearch cluster on AWS. It leverages Terraform for infrastructure provisioning and Ansible for Elasticsearch configuration and setup.

## Overview

The module performs the following key actions:

* **Provisions AWS Infrastructure:**
    * Creates an EC2 instance to host Elasticsearch.
    * Sets up a security group with necessary ingress and egress rules (SSH, Elasticsearch, etc.).
    * Creates an EC2 Key Pair for SSH access.
    * Configures an IAM role and instance profile for the EC2 instance, granting it the necessary permissions.
* **Configures Elasticsearch:**
    * Uses Ansible playbooks to:
        * Install and configure Elasticsearch within a Docker container.
        * Generate a `docker-compose.yml.j2` file.
        * Start the Elasticsearch cluster using Docker Compose.
        * Retrieves secrets (like the Elasticsearch password) from AWS Secrets Manager.
        * Dynamically configure seed hosts for cluster discovery.
        * Sets up DNS records in Route53.

## Prerequisites

Before using this module, ensure you have the following:

* **AWS Account:** You need an active AWS account with sufficient permissions to create EC2 instances, security groups, IAM roles, and Route53 records.
* **Terraform:** Install Terraform (version X.X.X or later) on your local machine.
* **Ansible:** Install Ansible (version X.X.X or later) on your local machine.
* **AWS CLI:** Install and configure the AWS Command Line Interface (CLI). This is used by the Ansible playbooks.
* **SSH Key Pair:** An SSH key pair to access the EC2 instance. The public key should be stored at the path specified by the `public_key_path` variable (default: `../../my-ec2-key.pub`).
* **Hosted Zone:** A Route 53 hosted zone to create DNS records for the Elasticsearch nodes.
* **Secrets Manager Secret:** A secret in AWS Secrets Manager containing the Elasticsearch password. The ARN of this secret is required.
* **EFS ID:** The ID of the Elastic File System.
* **Default Security Group ID:** The ID of the default security group.

## Module Inputs

The module accepts the following variables:

| Name                       | Description                                                                                                 | Type           | Default                        | Required |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------ | -------- |
| `public_key_path`          | Path to the public key file for SSH access.                                                                  | `string`       | `../../my-ec2-key.pub`          | No       |
| `ami_id`                   | The AMI ID to use for the EC2 instance.                                                                     | `string`       |                                | Yes      |
| `subnet_ids`               | List of IDs of the subnets where the EC2 instance will be launched.                                         | `list(string)` |                                | Yes      |
| `vpc_id`                   | ID of the VPC.                                                                                              | `string`       |                                | Yes      |
| `hosted_zone`              | The Route 53 hosted zone name.                                                                                | `string`       |                                | Yes      |
| `num_availability_zones` | Number of Availability Zones to use.                                                                          | `number`       |                                | Yes      |
| `hosted_zone_arn`          | ARN of the Route 53 hosted zone.                                                                              | `string`       |                                | Yes      |
| `hosted_zone_id`           | ID of the Route 53 hosted zone.                                                                               | `string`       |                                | Yes      |
| `amount`                   | Amount of instances.                                                                                          | `number`       | `3`                            | No       |
| `environment`              | Environment (e.g., "dev", "prod"). Used in naming resources.                                                 | `string`       |                                | Yes      |
| `aws_secret_arn`           | ARN of the AWS Secrets Manager secret containing the Elasticsearch password.                                 | `string`       |                                | Yes      |
| `efs_id`                   | The ID of the EFS.                                                                                           | `string`       |                                | Yes      |
| `sg_default_id`            | The ID of the default security group.                                                                        | `string`       |                                | Yes      |

## Module Outputs

The module exports the following values:

| Name                   | Description                                   |
| ---------------------- | --------------------------------------------- |
| `instance_public_ip`   | Public IP address of the EC2 instance.        |
| `instance_private_ip`  | Private IP address of the EC2 instance.       |
| `sg_id`                | ID of the security group created.             |

## Security

The module configures the following security group rules:

* **Ingress:**
    * SSH (port 22) access from anywhere (0.0.0.0/0). **Important:** For production environments, it is *highly* recommended to restrict this to specific IP addresses or CIDR blocks.
    * Elasticsearch traffic (port 3000) from anywhere (0.0.0.0/0).
* **Egress:**
    * All outbound traffic allowed (0.0.0.0/0).


## Important Considerations

* **Security:** The default security group rules allow access from anywhere (0.0.0.0/0). For production deployments, you *must* restrict access to specific IP addresses or CIDR blocks for both SSH (port 22) and Elasticsearch (port 3000).
* **EC2 Instance Type:** The default instance type is `t3.medium`. Adjust this based on your performance and cost requirements.
* **Subnets:** Ensure that the subnets you provide have a route to the internet (for the instance to be publicly accessible) or a NAT gateway (for private subnets).
* **Elasticsearch Configuration:** The Elasticsearch configuration is managed by Ansible. You can customize the `docker-compose.yml.j2` template in the `ansible/playbooks` directory to modify Elasticsearch settings.
* **Secrets Management:** The module uses AWS Secrets Manager to store the Elasticsearch password. Ensure that the EC2 instance's IAM role has the necessary permissions to access this secret.
* **Route 53:** The module creates DNS records in Route 53. Ensure that the hosted zone is correctly configured and that the IAM role has the necessary permissions to manage records in the hosted zone.
* **Docker Compose Template:** The `docker-compose.yml.j2` template is located in the `ansible/playbooks` directory. It is crucial to review and customize this template according to your specific Elasticsearch configuration needs, including network settings, resource allocation, and any desired plugins or modules.
* **User Data Template:** The `user_data.tpl` template is located in the module's directory. It's responsible for the initial setup of the EC2 instance, including installing Docker and running the Ansible playbook.

## Dependencies

* Terraform AWS Provider
* Ansible Core




