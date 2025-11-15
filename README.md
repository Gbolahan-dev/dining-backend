 Inu Dining Backend

This repository contains the backend API for the Inu Dining application, a NestJS service.

The entire infrastructure is fully automated and deployed using a production-grade Infrastructure as Code (IaC) pipeline.

 🚀 Core Features

  * Fully Automated CI/CD: Every `git push` to `main` (staging) or `git tag` (production) automatically builds, tests, and deploys the application.
  * Infrastructure as Code (IaC): The entire cloud infrastructure (VPC, GKE Cluster, IAM, Secrets) is defined declaratively using Terraform.
  * Scalable Hosting: The application is containerized with Docker and deployed to a Google Kubernetes Engine (GKE) cluster.
  * Automated Ingress & SSL: Uses a Helm-deployed NGINX Ingress Controller for traffic routing and Cert-Manager for free, auto-renewing Let's Encrypt SSL certificates.

 🛠️ Tech Stack

  * Application: NestJS (TypeScript)
  * Database: PostgreSQL (Neon)
  * Cloud Provider: Google Cloud Platform (GCP)
  * CI/CD: Google Cloud Build
  * IaC: Terraform
  * Orchestration: Google Kubernetes Engine (GKE)
  * Containerization: Docker
  * Container Registry: Google Artifact Registry
  * Service Mesh/Ingress: NGINX Ingress Controller (deployed via Helm)
  * SSL: Cert-Manager (deployed via Helm) with Let's Encrypt
  * Secret Management: Google Secret Manager
  * DNS: DuckDNS

 🏛️ System Architecture

This repository manages all backend infrastructure.

1.  A `git push` triggers a Google Cloud Build pipeline.
2.  Cloud Build runs `terraform apply` using the code in the `/infra` directory.
3.  Terraform performs the following automated steps:
      * Ensures GKE Cluster is Running: Manages the cluster state (`cluster.tf`).
      * Grants Permissions: Creates a Kubernetes `ClusterRoleBinding` to give Cloud Build the `cluster-admin` rights it needs to deploy (`k8s_rbac.tf`).
      * Deploys NGINX Controller: Installs the NGINX Ingress Controller from its official Helm chart (`ingress_controller.tf`).
      * Deploys Cert-Manager: Installs Cert-Manager from its Helm chart (`cert-manager.tf`) and creates a `ClusterIssuer` for Let's Encrypt (`issuer.tf`).
      * Deploys the Application: Deploys the NestJS application using its Helm chart (`helm.tf`). This step now uses `className: "nginx"` and the `cert-manager.io/cluster-issuer` annotation, automatically creating a valid SSL certificate.
      * Deploys Frontend Infrastructure: Also creates the Google Cloud Load Balancer and Backend Bucket for the frontend (`gcs_frontend_lb.tf`).

 ⚙️ Project Setup (One-Time Manual Steps)

To run this project from scratch, the following one-time manual steps are required:

1.  Grant Pipeline Permissions: The Cloud Build service account must be given `Editor` or equivalent IAM roles *before* it can run `terraform apply`.
    
    gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
        --member="serviceAccount:YOUR_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/editor"
    
2.  Point DNS Records: The DuckDNS domains (`inu-dining-api` and `api-prod`) must be manually pointed to the single External IP of the `nginx-ingress-controller-service`.
    
    Find the IP with:
    kubectl get service -n kube-system nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    
3.  Frontend DNS: The `inu-dining-frontend` DuckDNS domain must be pointed to the static IP created by the `gcs_frontend_lb.tf` file.
