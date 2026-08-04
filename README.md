# AWS EKS Platform

Production-style AWS platform for deploying and operating applications on Kubernetes using **Terraform**, **Amazon EKS**, **Helm**, and **ArgoCD**.

This repository focuses on **infrastructure and GitOps**. The application source code lives in a separate repository.

## Project Goals

* Provision AWS infrastructure using Terraform
* Deploy and manage an Amazon EKS cluster
* Use GitOps with ArgoCD for continuous deployment
* Deploy applications with Helm
* Monitor the platform with Prometheus, Grafana, and Loki
* Demonstrate production-oriented DevOps and Platform Engineering practices

## Architecture

```
Application Repository
        │
GitHub Actions (CI)
        │
Build Docker Images
        │
Push Images to Amazon ECR
        │
Update Deployment Configuration
        │
ArgoCD
        │
Amazon EKS
        │
Frontend + Backend
        │
Amazon RDS PostgreSQL
```

## Technology Stack

* AWS
* Terraform
* Amazon EKS
* Amazon ECR
* Amazon RDS PostgreSQL
* Helm
* ArgoCD
* NGINX Ingress Controller
* Prometheus
* Grafana
* Loki
* GitHub Actions

## Repository Structure

```
terraform/
helm/
argocd/
monitoring/
scripts/
docs/
.github/
```

## Responsibilities

This repository is responsible for:

* AWS infrastructure provisioning
* Kubernetes platform configuration
* GitOps configuration
* Application deployment configuration
* Monitoring and observability

This repository does **not** contain application source code.

## Deployment Flow

1. The application repository builds and tests the application.
2. Docker images are pushed to Amazon ECR.
3. Deployment configuration is updated.
4. ArgoCD detects the change.
5. ArgoCD deploys the new version to Amazon EKS.

## Status

Project is currently under development.

