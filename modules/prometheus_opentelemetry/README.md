# Prometheus and OpenTelemetry (I3) Deployment Module

This module automates the deployment of Prometheus and OpenTelemetry on AWS infrastructure using Terraform. It sets up an EC2 instance, configures IAM roles, and deploys the necessary services using Docker.

## Overview

This module is designed to deploy a monitoring stack consisting of Prometheus and OpenTelemetry.  It performs the following major actions:

* **EC2 Instance Provisioning**: Creates an EC2 instance to host the monitoring services.
* **IAM Configuration**: Configures IAM roles and policies to allow the EC2 instance to interact with other AWS services, such as ECR and Route 53.
* **Docker Deployment**: Installs and configures Docker on the EC2 instance.
* **Prometheus and OpenTelemetry Deployment**: Deploys Prometheus and OpenTelemetry as Docker containers.
* **Route 53 Integration**: Optionally manages a DNS record in Route 53 to point to the EC2 instance.
* **EFS Integration**: Mounts an Elastic File System (EFS) volume for persistent storage.

## Module Architecture

The deployment architecture includes the following components:

* **EC2 Instance**: A t3.medium EC2 instance running Ubuntu.
* **Prometheus**: A monitoring system for collecting and storing metrics.
* **OpenTelemetry Collector**:  A service that receives, processes, and exports telemetry data.
* **EFS**:  Elastic File System for shared and persistent storage.
* **Route 53**:  AWS DNS service.

## Prerequisites

Before using this module, ensure you have the following:

* Terraform installed and configured with AWS credentials.
* An existing VPC, subnets, and security groups.
* A Route 53 Hosted Zone.
* An EFS file system.
* An SSH key pair.

## Usage

To use this module, include it in your Terraform configuration as follows:

```terraform
module "prometheus" {
  source = "../modules/prometheus_opentelemetry"
  vpc_id             = var.vpc_id
  private_key_path   = var.private_key_path
  public_key_path    = var.public_key_path
  environment        = var.environment
  sg_wk              = module.sw_server.sg_id_server # Mismo grupo de seguridad que los workers
  hosted_zone_arn    = data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id     = data.aws_route53_zone.my_hosted_zone.id
  ami_id             = data.aws_ami.ubuntu_latest.id
  subnet_ids         = data.aws_subnets.private_subnets.ids
  efs_id             = var.efs_dns_name
  sg_default_id      = data.aws_security_group.default.id
  sg_grafana         = module.grafana.sg_id
}
```

## Module Inputs

The following table describes the input variables for the module:

|   | **Name** | **Description** | **Type** | **Default** | **Required** |
| --- | --- | --- | --- | --- | --- |
|   | `ami_id` | The ID of the Amazon Machine Image (AMI) that will be used for the EC2 instance. | `string` | N/A | Yes |
|   | `subnet_ids` | A list of subnet IDs where the EC2 instance will be launched. | `list(string)` | N/A | Yes |
|   | `environment` | The environment in which it will be deployed (e.g., `production`, `staging`, `development`). | `string` | N/A | Yes |
|   | `public_key_path` | The path to the public SSH key for the EC2 instance. | `string` | N/A | Yes |
|   | `vpc_id` | The ID of the VPC. | `string` | N/A | Yes |
|   | `hosted_zone_id` | The ID of the Route 53 Hosted Zone. | `string` | N/A | Yes |
|   | `hosted_zone_arn` | The ARN of the Route 53 Hosted Zone. | `string` | N/A | Yes |
|   | `efs_id` | The DNS name of the EFS file system. | `string` | N/A | Yes |
|   | `sg_default_id` | The ID of the default security group. | `string` | N/A | Yes |
|   | `sg_grafana` | The security group ID for Grafana. | `string` | N/A | Yes |
|   | `sg_wk` | The security group ID for the workers. | `string` | N/A | Yes |

## Module Outputs

The following table describes the outputs of the module:

|   | **Name** | **Description** |
| --- | --- | --- |
|   | `i3_sg_id` | The ID of the security group created for the Prometheus and OpenTelemetry instance. |

## Detailed Component Configuration

###   `main.tf`

* **`aws_key_pair`**: Creates an SSH key pair for accessing the EC2 instance.

* **`aws_instance`**:

    * Launches an EC2 instance with the specified AMI, instance type, and subnet.
    * Assigns an IAM instance profile to the EC2 instance.
    * Configures the root volume.
    * Applies tags to the instance.
    * Uses a `user_data` template to configure the instance on startup.

###   `iam.tf`

* **`aws_iam_role`**: Creates an IAM role for the EC2 instance.

* **`aws_iam_role_policy`**: Attaches an IAM policy to the role, granting permissions to:

    * Get authorization tokens from ECR.
    * Download layers and images from ECR.
    * Access S3 buckets.
    * Manage Route 53 records.

* **`aws_iam_instance_profile`**: Creates an instance profile for the EC2 instance.

###   `outputs.tf`

* **`i3_sg_id`**: Prints the ID of the security group created for the Prometheus and OpenTelemetry instance.

###   `sg.tf`

* **`aws_security_group`**: Creates a security group for the EC2 instance, allowing inbound traffic on ports 8889 (NFS), 22 (SSH), 4318 (OTLP), and 9090 (Prometheus), and all outbound traffic.

###   `user_data.tpl`

The `user_data.tpl` template configures the EC2 instance on startup. It performs the following actions:

* Updates the system and installs the necessary packages (nfs-common, unzip, dos2unix, curl, lsb-release, python3-apt).
* Saves the instance ID and DNS record name to files.
* Installs Docker.
* Installs the AWS CLI.
* Retrieves the instance's private IP address.
* Configures a Route 53 A record to point to the instance's private IP.
* Creates a systemd service to update the DNS record on each reboot.
* Mounts the EFS file system.
* Adds the ubuntu user to the docker group.
* Downloads the Docker Compose and Prometheus/OpenTelemetry configuration files from GitHub.
* Starts the Prometheus and OpenTelemetry services using Docker Compose.

###   `docker-compose.yml`

Defines the Docker Compose configuration for deploying Prometheus and OpenTelemetry:

* **`prometheus`**:

    * Builds a custom Prometheus image.
    * Maps port 9090.
    * Mounts a volume for Prometheus data.
    * Depends on the `otel-collector` service.

* **`backup`**:

    * Uses an Alpine image to perform Prometheus data backups to EFS.
    * Runs an rsync command every 6 hours.

* **`otel-collector`**:

    * Uses the `otel/opentelemetry-collector-contrib` image.
    * Maps ports 4318 (OTLP), 8889 (Prometheus), and 13133 (health check).
    * Mounts a volume for OpenTelemetry configuration.

###   `otel-collector-config.yml`

Configuration file for the OpenTelemetry collector:

* **`extensions`**: Configures a health check extension.
* **`receivers`**: Configures the OTLP receiver to accept data via gRPC and HTTP.
* **`exporters`**
