## Detailed Dockerfile Descriptions

### `Dockerfile.ansible`

This Dockerfile sets up a complete Ansible environment based on Ubuntu 24.04. It's designed to automate the configuration of EC2 instances and other systems using Ansible playbooks.

-   **Base Image:** Uses `ubuntu:24.04` as the base image to ensure an updated and stable Ubuntu environment.
-   **Dependencies:** Installs essential dependencies such as `curl`, `git`, `python3`, `sshpass`, and other tools necessary for running Ansible playbooks and manipulating remote systems.
-   **Ansible Installation:** Adds the official Ansible PPA repository and then installs Ansible, ensuring the latest version.
-   **Shell Configuration:** Configures an interactive shell as the default command, allowing users to run commands and playbooks manually within the container.
-   **Purpose:** This Dockerfile is ideal for development and deployment environments where you need to automate system configuration and management using Ansible.

### `Dockerfile.elastic`

This Dockerfile builds a custom Elasticsearch image based on the official Docker Elasticsearch image, adding extra functionalities for advanced configurations.

-   **Base Image:** Uses the official Elasticsearch image `docker.elastic.co/elasticsearch/elasticsearch:8.6.0` as the base.
-   **Sudo Installation:** Adds `sudo` to the container, which is useful for configurations that require elevated privileges.
-   **Sudoers Configuration:** Configures the `sudoers` file to allow the `elasticsearch` user to execute any command without a password, facilitating the automation of certain tasks within the container.
-   **Purpose:** This Dockerfile is useful for environments where you need to customize the Elasticsearch image with additional configurations for administration and automation.

### `Dockerfile.prometheus`

This Dockerfile builds a custom Prometheus image based on the official Ubuntu Prometheus image, adding extra functionalities for advanced configurations.

-   **Base Image:** Uses the `ubuntu/prometheus:2-24.04_stable` image as the base.
-   **Sudo Installation:** Adds `sudo` to the container, which is useful for configurations that require elevated privileges.
-   **Sudoers Configuration:** Configures the `sudoers` file to allow the `ubuntu` user to execute any command without a password, facilitating the automation of certain tasks within the container.
-   **ENTRYPOINT Overriding:** Overrides the default `ENTRYPOINT` to allow greater flexibility in running commands within the container.
-   **Purpose:** This Dockerfile is useful for environments where you need to customize the Prometheus image with additional configurations for administration and automation.

### `Dockerfile.worker.alpine`

This Dockerfile builds an optimized worker application image for Alpine, using a multi-stage build strategy to minimize the final image size.

-   **Builder Stage:** Uses `golang:1.24-alpine` to compile the `xq` tool from its Git repository.
-   **Builder2 Stage:** Uses `flexvega/simple-worker:1.0.0-alpine` to copy the worker application.
-   **Final Image:** Uses `alpine:latest` as the base image for the final image.
-   **Dependencies:** Installs essential dependencies such as `bash`, `curl`, `jq`, `python3`, `aws-cli`, and other tools necessary for running the worker application.
-   **Binary Copying:** Copies the `xq` and `app-bluengo-worker` binaries from the build stages.
-   **Working Directory Configuration:** Sets `/app` as the working directory.
-   **Execution Permissions:** Ensures that the `app-bluengo-worker` binary has execution permissions.
-   **Port Exposure:** Exposes port 8080 for the worker application.
-   **Entry Point:** Configures the entry point to run the worker application.
-   **Purpose:** This Dockerfile is ideal for creating a lightweight and Alpine-optimized worker application image with all the necessary dependencies.