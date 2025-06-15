# One-Click Jenkins Pipeline Deployment

This project implements a fully automated DevOps pipeline using Jenkins (in Docker) that:

- Provisions a VM on Azure using Terraform
- Installs a web server on that VM using Ansible
- Deploys a static web app to that server via Ansible
- Runs all these steps from a single Jenkins pipeline

## Technology Stack

- Docker - Host Jenkins in a container
- Jenkins - Automate the workflow
- Terraform - Provision the virtual machine
- Ansible - Configure the VM and deploy the web app
- Azure - Host the virtual machine
- Git - Store Jenkinsfile, code, playbooks, and Terraform code

## Project Structure

```
project/
├── terraform/
│   ├── main.tf
│   └── variables.tf
├── ansible/
│   ├── install_web.yml
├── app/
│   └── index.html
├── Jenkinsfile
└── README.md
```

## Setup Instructions

1. Start Jenkins in Docker:

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which terraform):/usr/local/bin/terraform \
  -v $(which ansible-playbook):/usr/local/bin/ansible-playbook \
  -v $(pwd):/workspace \
  jenkins/jenkins:lts
```

2. Configure Jenkins:

   - Install required plugins: Git, Pipeline, SSH Agent
   - Add credentials for SSH private key (used by Ansible)

3. Configure Azure credentials for Terraform

4. Run the Jenkins pipeline

## Pipeline Steps

1. Terraform creates Azure VM
2. Ansible installs and configures web server
3. Static site is deployed
4. Deployment is verified
