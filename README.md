# 🚀 Automated Container Deployment on AWS with Terraform, Ansible, Docker & GitHub Actions

![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)
![Ansible](https://img.shields.io/badge/Config%20Mgmt-Ansible-red)
![Docker](https://img.shields.io/badge/Container-Docker-blue)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)
 
**Prakash Thangaraj**  
**20095532**  
**Networks and Systems Administration**  
**Dublin Business School**  

---

## Project Overview

This project demonstrates the design and implementation of a complete cloud automation pipeline that provisions infrastructure, configures a server, deploys a containerized web application, and makes it accessible through a browser.

All development and deployment tasks were performed on a MacBook Air using free and open-source tools under the AWS Free Tier.

### Automation Flow

Machine → Terraform → AWS EC2 → Ansible → Docker → Browser

The system automatically:
- Creates infrastructure on AWS
- Configures the server environment
- Deploys a containerized Node.js web application
- Makes the application accessible via a public IP

---

## Tools and Their Purpose

| Tool | Purpose |
|------|----------|
| Terraform | Provisions AWS EC2 instance, security group, and IAM role |
| Ansible | Connects to EC2, installs Docker, deploys container |
| Docker + Node.js | Runs the web application inside a lightweight container |
| AWS CLI | Manages AWS resources and retrieves instance information |
| Git + GitHub | Version control and source code management |

This repository contains a fully automated DevOps pipeline that provisions an AWS EC2 instance, configures it with Ansible, containerizes a static website with Docker, and continuously deploys updates via GitHub Actions. The website is accessible at a permanent Elastic IP and updates automatically on every push to the `main` branch.


---

## 📋 Prerequisites

- An AWS account (Free Tier eligible)
- Terraform ≥ 1.5.0
- Ansible (Linux/WSL)
- AWS CLI installed and configured (`aws configure`)
- Git
- SSH key pair (`~/.ssh/aws-key`) – generate with:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-key -N "" -m PEM
```

- An allocated Elastic IP in your AWS account (region `eu-west-1`)

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ipsrepo/network_automated_deployment.git
cd network_automated_deployment

# Configure AWS CLI (if not already)
aws configure

# Update the Elastic IP in terraform/variables.tf (default: 52.48.24.168)
# Then run the deployment script
chmod +x start.sh  # On WSL/Linux
./start.sh
```

Your website will be live at `http://<ELASTIC_IP>`.

---

## 📁 Repository Structure

```
NETWORK_AUTOMATED_DEPLOYMENT/
│
├── .github/
│   └── workflows/
│       └── deploy.yml          # Github action scripts
│
├── ansible/                    # Ansible playbook for server config
│   ├── ansible.cfg             
│   ├── inventory.ini
│   └── playbook.yml            
│
├── app/                        # Web application (HTML + Dockerfile)
│   ├── Dockerfile
│   └── index.html
│
├── aws/
│
├── terraform/                  # Terraform configuration (EC2, SG, EIP)
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   └── variables.tf
│
├── .gitignore
├── README.md
└── start.sh                    # Local deployment scripts Bash

```

## 🔧 Detailed Setup

### 1. AWS Preparation

- Create an IAM user with `AdministratorAccess` and generate access keys.
- Configure the AWS CLI: `aws configure`
- Allocate an Elastic IP in the `eu-west-1` region (or update the variable).

### 2. Terraform – Infrastructure as Code

- Navigate to `terraform/` and review `variables.tf`.
- Update `elastic_ip_address` with your allocated Elastic IP.
- Run:

```bash
terraform init
terraform apply -auto-approve
```

- Note the outputs: `instance_id`, `elastic_ip`, `website_url`.

### 3. Ansible – Configuration Management

- Ensure your SSH key is at `~/.ssh/aws-key` with correct permissions.
- Test SSH connection:

```bash
ssh -i ~/.ssh/aws-key ec2-user@<ELASTIC_IP>
```

- Run the playbook manually:

```bash
cd ansible
ansible-playbook -i "<ELASTIC_IP>," -u ec2-user --private-key ~/.ssh/aws-key playbook.yml
```

### 4. GitHub Actions – CI/CD Pipeline

Add the following secrets to your repository:

**Settings → Secrets and variables → Actions**

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (e.g., `eu-west-1`)
- `SSH_PRIVATE_KEY` (content of `~/.ssh/aws-key`, including `-----BEGIN` and `-----END` lines)
- `SSH_USER` (`ec2-user`)
- `ELASTIC_IP` (your Elastic IP)

Push any change to the `main` branch to trigger automatic deployment.

### 5. Local Deployment Scripts

Two convenience scripts are provided in the `scripts/` folder:

- **`start.sh` (Bash)** – For WSL/Linux; reads Terraform outputs, starts instance if stopped, waits for SSH, runs Ansible, and opens the website.

Make scripts executable (on WSL):

```bash
  ./start.sh
```

---

## 🧪 Testing

Visit:

```
http://<ELASTIC_IP>
```

Verify Docker:

```bash
ssh -i ~/.ssh/aws-key ec2-user@<ELASTIC_IP>
docker ps
docker logs web-app
```



## 🙌 Acknowledgements

- HashiCorp Terraform  
- Ansible Community  
- Docker  
- GitHub Actions  
- AWS Free Tier 
- WSL 

---

**Happy Coding!** 🚀  
Prakash Thangaraj  
Made with dedication and precision ❤️
