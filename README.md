# DevOps Infrastructure as Code Project

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?logo=docker&logoColor=white)

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Accessing the Application](#accessing-the-application)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [License](#license)

## Project Overview
This project automates the deployment of a web application on AWS using:
- **Terraform** for infrastructure provisioning
- **Docker** for application containerization
- **Git** for version control

## Repository Structure
devops-assignment/
├── .gitignore
├── README.md
├── app/
│ ├── Dockerfile
│ └── index.html
└── terraform/
├── main.tf
└── .terraform.lock.hcl

## Prerequisites
- AWS Account with IAM permissions
- Terraform v1.5+ ([Install guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- Docker Engine ([Install guide](https://docs.docker.com/engine/install/))
- AWS CLI configured ([Setup guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))

## Deployment Steps

### 1. Infrastructure Provisioning
```bash
cd terraform
terraform init
terraform apply

### 2. Application Deployment

# SSH into instance
```bash
ssh -i ../keys/devops-key.pem ec2-user@$(terraform output -raw instance_public_ip)

# Build and run container
```bash
cd ~/app
docker build -t devops-app .
docker run -d -p 80:80 --name devops-container devops-app

### 3. Access the Application
http://<EC2_PUBLIC_IP>


## Configuration Details
### Terraform Resources

#### 1. VPC with Internet Gateway

#### 2. Public subnet with route table

#### 3. Security group allowing:
- SSH (port 22) from your IP
- HTTP (port 80) from anywhere

### 4. EC2 instance with:
- Amazon Linux 2 AMI
- t2.micro instance type
- Docker pre-installed via user-data

## Docker Container
- Nginx Alpine base image
- Serves static HTML page
- Exposes port 80

## Cleanup
```bash
terraform destroy