# RSS Engine Infrastructure Deployment with Terraform

This repository contains Terraform configurations to deploy a complete infrastructure for the RSS Engine on AWS. The setup leverages modules to provision and configure various components, including servers, workers, Elasticsearch, Prometheus, and Grafana.

## Project Structure

The project is organized into the following files:

- **main.tf**:  
  The primary Terraform configuration file that orchestrates the deployment by invoking and connecting various modules.

- **key.tf**:  
  Defines the configuration to create an AWS SSH key pair. This key pair is used for secure access to the EC2 instances.

- **data.tf**:  
  Contains data sources that allow Terraform to query information about existing AWS resources (such as VPCs, subnets, and security groups).

- **backend.tf**:  
  Configures the Terraform backend, which in this case is an S3 bucket. The backend stores the Terraform state file.

- **secret.tf**:  
  Manages the generation and secure storage of secrets (e.g., passwords) using AWS Secrets Manager.

- **terraform.tfvars**:  
  Stores the values for input variables defined in `variables.tf`.

- **variables.tf**:  
  Defines the variables used throughout the Terraform configuration.

## File Descriptions

### main.tf
The `main.tf` file is the primary entry point for the Terraform configuration. It defines and orchestrates the deployment of various infrastructure components by invoking several Terraform modules. It also establishes dependencies among these modules, ensuring that resources are created in the correct order.

### key.tf
The `key.tf` file is responsible for creating an AWS SSH key pair. The key pair consists of a public key (stored in AWS) and a private key (kept by the user), enabling secure SSH access to the EC2 instances.

### data.tf
The `data.tf` file defines data sources that Terraform uses to fetch information about existing AWS resources. Instead of creating new resources, these data sources allow Terraform to query details about resources that already exist, such as:
- VPCs (Virtual Private Clouds)
- Subnets
- Security Groups
- Hosted zones in Route 53

### backend.tf
The `backend.tf` file configures Terraform's backend, which determines where the Terraform state file is stored. In this setup, the backend is an S3 bucket that provides remote storage for the state file, facilitating team collaboration and state locking to prevent conflicts.

### secret.tf
The `secret.tf` file handles secret management. Rather than hardcoding passwords or sensitive information directly in the Terraform configuration, this file defines how to securely generate and store these secrets using AWS Secrets Manager.

### terraform.tfvars
The `terraform.tfvars` file contains the values for input variables defined in `variables.tf`. Variables allow you to customize the Terraform deployment without modifying the main configuration code. Examples of values include:
- VPC IDs
- AWS regions
- Paths to SSH key files
- Environment names
- EFS (In this case is already assigned one)

### variables.tf
The `variables.tf` file defines all the variables used in the Terraform configuration. Each variable has a name, a data type, and a description. By using variables, the configuration becomes more reusable and customizable. For instance, instead of hardcoding a specific VPC ID in multiple places, you define a variable (e.g., `vpc_id`) and reference it throughout the configuration.

## Modules

The deployment is structured into several Terraform modules. Each module encapsulates a set of related AWS resources that are deployed and managed together. The modules used in this project include:

- **sw_server**:  
  Deploys the main server of the application.
  
- **sw_workers**:  
  Deploys the workers that process background tasks.
  
- **elastic**:  
  Deploys an Elasticsearch cluster for data storage and search.
  
- **prometheus**:  
  Deploys Prometheus and OpenTelemetry for monitoring and metrics collection.
  
- **grafana**:  
  Deploys Grafana for metrics visualization and dashboard creation.

Each module defines the necessary AWS resources for its component, such as EC2 instances, security groups, volumes, and network configurations.


