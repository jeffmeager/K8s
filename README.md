# wiz-technical-exercise

## Overview

This project sets up a containerized web application running on an AWS EKS cluster and an instance running MongoDB, which performs backups to an S3 bucket.

## File Structure

- `terraform/`: Contains Terraform configuration files for setting up AWS resources.
  - `main.tf`: Main configuration file.
  - `variables.tf`: Variables used in the Terraform configuration.
  - `outputs.tf`: Outputs from the Terraform configuration.
  - `provider.tf`: Provider configuration for AWS.
- `kubernetes/`: Contains Kubernetes manifests for deployments and services.
  - `deployments/webapp-deployment.yaml`: Deployment manifest for the web application.
  - `services/webapp-service.yaml`: Service manifest for the web application.
- `scripts/`: Contains scripts for managing the environment.
  - `mongodb-backup.sh`: Script to back up MongoDB data and upload to S3.
- `README.md`: This file.

## Steps to Set Up the Environment

1. **Initialize and Apply Terraform Configuration**
    ```bash
    cd terraform
    terraform init
    terraform apply
    ```

2. **Configure kubectl for EKS**
    ```bash
    aws eks --region us-west-2 update-kubeconfig --name example-eks-cluster --profile devops-lead
    ```

3. **Deploy Web Application to EKS**
    ```bash
    cd ../kubernetes/deployments
    kubectl apply -f webapp-deployment.yaml
    cd ../services
    kubectl apply -f webapp-service.yaml
    ```

4. **Set Up MongoDB Backup to S3**
    - Create a script (`mongodb-backup.sh`) to back up MongoDB and upload to S3.
    - Set up a cron job to run the backup script daily.

## Verification

- Access the web application via the LoadBalancer URL provided by the EKS service.
- Verify that MongoDB backups are successfully uploaded to the S3 bucket.
