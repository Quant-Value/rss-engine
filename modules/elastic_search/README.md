# Elasticsearch Deployment Module

This module automates the deployment of an Elasticsearch cluster on AWS EC2 instances, configured for use with the i4-rss-engine. It sets up the necessary infrastructure, including EC2 instances, IAM roles, security groups, EFS integration, and Docker, and configures Elasticsearch for secure and efficient operation. It also configures DNS records using Route53.

## Features

* **EC2 Instance Deployment:** Provisions multiple EC2 instances to host the Elasticsearch cluster.
* **IAM Role and Policy:** Creates an IAM role with the necessary permissions for the EC2 instances to access other AWS services, such as ECR, S3, Route 53, and Secrets Manager.
* **Security Group Configuration:** Configures security groups to allow Elasticsearch communication (ports 9200 and 9300) and SSH access.
* **EFS Integration:** Mounts an Amazon EFS volume to the EC2 instances for persistent Elasticsearch snapshot storage.
* **Docker Installation:** Installs and configures Docker on the EC2 instances.
* **Elasticsearch Deployment:** Deploys Elasticsearch using Docker Compose, with configurations for cluster formation, security, and data persistence.
* **Route 53 Integration:** Creates or updates DNS A records in Route 53, pointing to the private IPs of the EC2 instances. This allows for accessing the Elasticsearch cluster using hostnames.
* **Automatic DNS Update:** Sets up a systemd service to automatically update the Route 53 DNS records whenever the EC2 instances restart and their private IP addresses change.
* **Secrets Management:** Retrieves the Elasticsearch admin password from AWS Secrets Manager.
* **SSL/TLS Security:** Configures Elasticsearch with SSL/TLS using certificates from S3.

## Architecture

The architecture consists of:

* Multiple EC2 instances running Ubuntu.
* An EFS volume mounted to the EC2 instances for persistent snapshot storage.
* Security Groups allowing access to the EC2 instances.
* IAM Role and Instance Profile.
* Route 53 for DNS management.
* Docker and Docker Compose.
* Elasticsearch.
* AWS Secrets Manager.
* S3 for certificate storage.

## Prerequisites

Before using this module, ensure you have the following:

* An AWS account.
* An existing VPC, Subnets, and Security Groups.
* A registered domain and a Hosted Zone in Route 53.
* An SSH key pair for accessing the EC2 instances.
* The AMI ID for the EC2 instances.
* The ARN of the hosted zone.
* The ID of the hosted zone.
* The ARN of the AWS Secret containing the Elasticsearch admin password.
* The DNS name of the EFS volume.
* An S3 bucket containing SSL/TLS certificates.

## Getting Started

### Usage

**Define variables:**
Create a `terraform.tfvars` file or set the following variables in your Terraform configuration:

**How to call the module:**

```terraform
module "elasticsearch" {
  source = "../modules/elasticsearch_deployment"

  vpc_id = var.vpc_id
  public_key_path = var.public_key_path
  amount = 3
  ami_id = data.aws_ami.ubuntu_latest.id
  subnet_ids = data.aws_subnets.private_subnets.ids
  hosted_zone = data.aws_route53_zone.my_hosted_zone.id
  num_availability_zones = local.num_availability_zones
  hosted_zone_arn = data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id = data.aws_route53_zone.my_hosted_zone.id
  environment = var.environment
  aws_secret_arn = aws_secretsmanager_secret.rss_engine_imatia.arn
  efs_dns_name = var.efs_dns_name
  sg_default_id = data.aws_security_group.default.id
  sg_grafana = data.aws_security_group.grafana.id
  sg_otel = data.aws_security_group.otel.id
  sg_sw_worker = data.aws_security_group.worker.id
  aws_key_name = aws_key_pair.key_ec2.key_name
}
``` 
## Inputs

| Name                     | Description                                                                                                                                                                                                 | Type           | Default                | Required |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------------------- | -------- |
| `ami_id`                 | The AMI ID to use for the EC2 instances.                                                                                                                                                                   | `string`       | n/a                    | Yes      |
| `aws_secret_arn`         | ARN of the AWS Secrets Manager secret containing the Elasticsearch admin password.                                                                                                                          | `string`       | n/a                    | Yes      |
| `environment`            | Environment (e.g., `dev`, `prod`).                                                                                                                                                                         | `string`       | n/a                    | Yes      |
| `efs_dns_name`           | The DNS name of the EFS volume.                                                                                                                                                                           | `string`       | n/a                    | Yes      |
| `hosted_zone_arn`        | ARN of the Route 53 Hosted Zone.                                                                                                                                                                           | `string`       | n/a                    | Yes      |
| `hosted_zone_id`         | ID of the Route 53 Hosted Zone.                                                                                                                                                                            | `string`       | n/a                    | Yes      |
| `num_availability_zones` | Number of Availability Zones to use.                                                                                                                                                                       | `number`       | n/a                    | No       |
| `public_key_path`        | Path to the SSH public key file associated with the private key for accessing the EC2 instances.                                                                                                             | `string`       | `../../my-ec2-key.pub` | No       |
| `sg_default_id`          | Security Group to assign to the instances.                                                                                                                                                                   | `string`       | n/a                    | Yes      |
| `subnet_ids`             | List of IDs of the subnets where the EC2 instances will be launched.                                                                                                                                       | `list(string)` | n/a                    | Yes      |
| `vpc_id`                 | ID of the VPC where the EC2 instances will be launched.                                                                                                                                                     | `string`       | n/a                    | Yes      |
| `sg_grafana`             | Security group ID for Grafana.                                                                                                                                                                             | `string`       | n/a                    | Yes      |
| `sg_otel`                | Security group ID for OpenTelemetry.                                                                                                                                                                       | `string`       | n/a                    | Yes      |
| `sg_sw_worker`           | Security group ID for worker services.                                                                                                                                                                     | `string`       | n/a                    | Yes      |
| `aws_key_name`           | Name of the AWS key pair used for SSH access to the EC2 instances.                                                                                                                                          | `string`       | n/a                    | Yes      |
| `amount`                 | Number of EC2 instances to launch for the Elasticsearch cluster.                                                                                                                                          | `number`       | `3`                    | No       |

## Outputs

| Name                  | Description                                        |
| --------------------- | -------------------------------------------------- |
| `instance_private_ips` | The private IP addresses of the EC2 instances.     |
| `sg_id`               | The ID of the security group created.             |

## User Data

The `user_data.tpl` template configures the EC2 instances on startup. Here's a breakdown of the actions performed:

* System updates and dependency installation (unzip, curl, nfs-common, git, python3-pip, docker).
* Hostname configuration.
* EFS volume mounting and persistent mount configuration via `/etc/fstab`.
* AWS CLI installation.
* Docker installation and startup.
* Adds the `ubuntu` user to the `docker` group.
* Retrieves the instance ID and private IP.
* Configures Route 53 A records with the instances' private IPs.
* Creates a systemd service (`update-dns.service`) to keep the Route 53 records updated on reboot.
* Clones the Elasticsearch Docker Compose file and Ansible playbooks from GitHub.
* Retrieves the Elasticsearch admin password from AWS Secrets Manager.
* Configures Elasticsearch using Ansible playbooks.
* Generates SSL certificates.
* Starts Elasticsearch using Docker Compose.

## Ansible Playbook (`install2.yml`)

The `install2.yml` playbook configures the Elasticsearch nodes. Here's a breakdown of the tasks performed:

* **Debug environment variables:** Displays the values of `NUM_NODES` and `INDEX` environment variables.
* **Set the INDEX variable:** Loads the `INDEX` environment variable and saves it as `INDEX_VAR`.
* **Define ENVIRON variable:** Sets the `ENVIRON` variable with a default value of `demo`.
* **Retrieve secret from AWS Secrets Manager:** Fetches the Elasticsearch password from AWS Secrets Manager.
* **Set the password as a variable:** Extracts the password from the Secrets Manager output and saves it as `elasticpass`.
* **Generate `seed_hosts` list with DNS names:** Creates a list of seed hosts using DNS names based on the number of nodes.
* **Generate excluded host:** Creates the DNS name of the current node to be excluded from the seed hosts list.
* **Generate `seed_hosts` excluding the node with the index:** Creates a list of seed hosts excluding the current node.
* **Resolve DNS names to IPs using dig:** Resolves the DNS names of the seed hosts to their corresponding IPs.
* **Store resolved IPs:** Stores the resolved IPs in a list.
* **Show resolved IPs:** Displays the resolved IPs.
* **Debug `seed_hosts` list:** Displays the generated seed hosts lists.
* **Generate `docker-compose.yml` from template:** Creates the `docker-compose.yml` file from the `docker-compose.yml.j2` template, configuring Elasticsearch with the retrieved password and seed host IPs.
* **Start Elasticsearch using Docker Compose:** Starts the Elasticsearch cluster using Docker Compose.

