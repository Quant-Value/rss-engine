# AWS SW Worker Deployment Module

This Terraform module automates the deployment of SW Worker instances on AWS EC2. It configures the necessary infrastructure, including EC2 instance provisioning, IAM roles, and Docker Compose setup. It also integrates with Route 53 for DNS management and uses Ansible for application configuration.

## Features

* **EC2 Instance Provisioning:** Deploys multiple EC2 instances for SW Workers.
* **IAM Role and Policy:** Creates an IAM role with required permissions for ECR, S3, Route 53, and Secrets Manager access.
* **Docker Compose Deployment:** Sets up and runs Docker containers using a provided `docker-compose.yml.j2` template.
* **Route 53 DNS Management:** Automatically registers EC2 instance IPs in Route 53.
* **Automatic DNS Update on Reboot:** Configures instances to update their DNS records on startup.
* **Ansible Configuration:** Uses Ansible to install dependencies, configure the application, and manage the Docker Compose deployment.
* **Secrets Management:** Retrieves sensitive data (e.g., database passwords) from AWS Secrets Manager.

## Architecture

The architecture consists of:

* Multiple EC2 instances running a specified AMI.
* An IAM role with necessary permissions.
* Docker Compose for container management.
* Route 53 for DNS management.
* AWS Secrets Manager for secure secret retrieval.
* Ansible for automating instance configuration and application deployment.

## Prerequisites

Before using this module, ensure you have the following:

* An AWS account with appropriate permissions.
* An existing VPC and subnets.
* A registered domain and hosted zone in Route 53.
* An SSH key pair for EC2 instance access.
* The AMI ID for the EC2 instances.
* The ARN and ID of the Route 53 hosted zone.
* The ARN of the AWS Secrets Manager secret.
* The Security Group ID for the SW Server Instances.

## Getting Started

### Usage

To use this module, define the required variables in your Terraform configuration and then apply the module.

## Module Invocation

To invoke this module in your Terraform configuration, use the following block of code:

```terraform
module "sw_workers" {
  source = "../modules/sw_worker"
  sg_group_server=module.sw_server.sg_id_server
  dns_name_server=module.sw_server.dns_name_server
  aws_region=var.aws_region
  vpc_id=var.vpc_id
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment
  subnet_ids=data.aws_subnets.public_subnets.ids
  amount= 3
  num_availability_zones=local.num_availability_zones
  hosted_zone_arn=data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id=data.aws_route53_zone.my_hosted_zone.id
  aws_secret_arn=data.aws_secretsmanager_secret.rss_engine_imatia.arn
  ami_id=data.aws_ami.ubuntu_latest.id
  aws_key_name=aws_key_pair.key_ec2.key_name
  depends_on=[module.sw_server,aws_secretsmanager_secret_version.rss_engine_imatia_version]
}
``` 

## Inputs

| Name                     | Description                                                                                             | Type          | Default                | Required |
| :----------------------- | :------------------------------------------------------------------------------------------------------ | :------------ | :--------------------- | :------- |
| `aws_region`             | AWS region for deployment.                                                                               | `string`      | n/a                    | Yes      |
| `ami_id`                 | The AMI ID to use for the EC2 instances.                                                                 | `string`      | n/a                    | No       |
| `private_key_path`       | Path to the SSH private key file.                                                                          | `string`      | n/a                    | No       |
| `public_key_path`        | Path to the SSH public key file.                                                                           | `string`      | n/a                    | No       |
| `vpc_id`                 | ID of the VPC.                                                                                             | `string`      | n/a                    | Yes      |
| `environment`            | Environment (dev/prod).                                                                                     | `string`      | n/a                    | Yes      |
| `amount`                 | Number of EC2 instances to deploy.                                                                       | `number`      | 3                      | No       |
| `sg_group_server`        | Security group ID of the SW Server.                                                                        | `string`      | n/a                    | Yes      |
| `dns_name_server`        | DNS name of the SW Server.                                                                               | `string`      | n/a                    | Yes      |
| `hosted_zone_arn`        | ARN of the Route 53 hosted zone.                                                                           | `string`      | n/a                    | Yes      |
| `hosted_zone_id`         | ID of the Route 53 hosted zone.                                                                            | `string`      | n/a                    | Yes      |
| `aws_secret_arn`         | ARN of the AWS Secrets Manager secret.                                                                     | `string`      | n/a                    | Yes      |
| `subnet_ids`             | List of subnet IDs where the instances will be deployed.                                                | `list(string)` | n/a                    | Yes      |
| `num_availability_zones` | Number of Availability Zones to use.                                                                       | `number`      | n/a                    | Yes      |
| `aws_key_name`           | Name of the AWS key pair for SSH access.                                                                   | `string`      | n/a                    | Yes      |

## User Data (`user_data.tpl`)

The `user_data.tpl` script configures the EC2 instances on startup. It performs the following actions:

* Updates packages and installs dependencies (Docker, AWS CLI, Git).
* Installs and configures Docker.
* Configures Route 53 DNS records.
* Sets up a systemd service to update DNS records on reboot.
* Generates SSH keys and adds them to authorized keys.
* Builds an Ansible Docker image.
* Downloads and executes Ansible playbooks.
* Retrieves secrets from AWS Secrets Manager.

## `Dockerfile.ansible` Description

This Dockerfile is used to build an Ubuntu-based Docker image with Ansible pre-installed, along with other dependencies required to run Ansible playbooks.

### Detailed Description

1. **Base Image:**
   - The base image `ubuntu:24.04` is used, ensuring an up-to-date Ubuntu environment.

2. **Environment Variables:**
   - The environment variable `DEBIAN_FRONTEND=noninteractive` is set to prevent the installation process from prompting user interaction, which is crucial in automated environments.

3. **Updating and Installing Dependencies:**
   - The command `apt-get update` is executed to update the package repositories.
   - Several necessary dependencies are installed:
     - `software-properties-common`: Allows the addition of PPA repositories.
     - `curl`: A tool to transfer data using URLs.
     - `git`: A version control system.
     - `python3`, `python3-pip`, `python3-setuptools`: Python dependencies required for Ansible and other tools.
     - `sshpass`: Provides a non-interactive way to supply passwords to SSH.
   - The APT package lists are removed to reduce the size of the final image.

4. **Adding the Ansible Repository:**
   - The official Ansible PPA (`ppa:ansible/ansible`) is added and the repositories are updated, ensuring that the latest version of Ansible is installed.

5. **Installing Ansible:**
   - Ansible is installed from the newly added PPA repository.
   - The APT package lists are removed again to keep the image as small as possible.

6. **Verifying Ansible Installation:**
   - The command `ansible --version` is executed to verify that Ansible has been installed correctly.

7. **Exposing the SSH Port (Optional):**
   - Port 22 is exposed (`EXPOSE 22`). This is optional and only necessary if you plan to use SSH to connect to the container.

8. **Default Command:**
   - The default command is set to `CMD ["/bin/bash"]`, which initiates an interactive shell within the container, allowing users to execute commands manually or run Ansible playbooks.



## `Dockerfile.worker.alpine` Description

This Dockerfile is used to build a custom Docker image that includes Ansible and the necessary tools to execute Ansible playbooks on the EC2 instance.

### Detailed Description

1.  **Builder Stage:**
    * The base image `golang:1.24-alpine` is used for this stage.
    * `git` is installed within the container.
    * The repository `https://github.com/sibprogrammer/xq.git` is cloned, and the `xq` binary is compiled. This allows the use of `xq` in Ansible playbooks.

2.  **Final Stage:**
    * The base image `alpine:latest` is used.
    * Necessary dependencies are installed: `bash`, `curl`, `jq`, `python3`, `py3-pip`, `groff`, `less`, `unzip`, `ca-certificates`, `aws-cli`. These tools are essential for running Ansible and performing AWS operations.
    * The `xq` and `app-bluengo-worker` binaries are copied from the builder stage.
    * The working directory is set to `/app`.
    * Execution permissions are ensured for the `app-bluengo-worker` binary.
    * Port 8080 is exposed.
    * The entry point to execute the Go application is set.


## `docker-compose-workers.yml.j2` Description

This `docker-compose.yml.j2` file defines the configuration for a Docker service named `my_worker`, which is used to run the worker application. This file is designed to be used with Docker Compose and may include Jinja2 variables (like `{{ DNS_SERVER }}`) that are replaced during Ansible execution.

### Detailed Description

1.  **Services (`services`):**
    * Defines a service named `my_worker`.

2.  **Build (`build`):**
    * `build: .` indicates that Docker should build the image from the `Dockerfile` present in the same directory as this `docker-compose.yml.j2` file.

3.  **Container Name (`container_name`):**
    * `container_name: my_worker` assigns the name `my_worker` to the container.

4.  **Environment Variables (`environment`):**
    * `DOCKER_BUILDKIT=1` enables Docker BuildKit, which can improve image build speed.

5.  **Volumes (`volumes`):**
    * `/home/ubuntu/scripts:/app/scripts` mounts the `/home/ubuntu/scripts` directory from the EC2 instance into the container at `/app/scripts`. This allows the container to access the scripts needed for the worker application.
    * `/home/ubuntu/.aws:/.aws` mounts the `/.aws` directory from the EC2 instance into the container at `/.aws`. This allows the container to use the AWS credentials stored on the EC2 instance.

6.  **Deploy (`deploy`):**
    * `resources` defines resource limits for the container.
        * `cpus: '1.6'` limits CPU usage to 1.6 cores.

7.  **Restart (`restart`):**
    * `restart: unless-stopped` configures Docker to automatically restart the container unless it is explicitly stopped.

8.  **Working Directory (`working_dir`):**
    * `working_dir: /app` sets the working directory of the container to `/app`.

9.  **Entry Point (`entrypoint`):**
    * `entrypoint: ["./app-bluengo-worker", "worker"]` defines the main command that is executed when the container starts. This runs the worker application.

10. **Command (`command`):**
    * `command: -server http://{{ DNS_SERVER }}:8080 -slots=8` provides additional arguments to the worker application. `{{ DNS_SERVER }}` is a variable that is replaced with the DNS name of the server during Ansible execution.


