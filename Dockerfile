FROM jenkins/jenkins:lts

USER root

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3 \
    python3-pip \
    gnupg \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Python virtual environment
RUN apt-get update && apt-get install -y python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment for Ansible
RUN python3 -m venv /opt/ansible_venv
ENV PATH="/opt/ansible_venv/bin:$PATH"

# Install Ansible in the virtual environment
RUN /opt/ansible_venv/bin/pip install --no-cache-dir ansible

# Verify installations
RUN terraform --version && \
    ansible --version && \
    az --version

# Switch back to Jenkins user
USER jenkins
