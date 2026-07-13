# StarSigns

A small Flask + MongoDB web app, deployed to AWS via Terraform and Kubernetes (EKS). Built as a hands-on cloud security exercise — several misconfigurations are **intentional**, not oversights (see below).

## Repo layout

- **`app/`** — Flask + PyMongo web app, containerized via `app/Dockerfile`
- **`terraform/`** — AWS infrastructure: VPC, EKS, an EC2 MongoDB instance, S3 buckets, CloudTrail, GuardDuty, AWS Config
- **`k8s/`** — Kubernetes manifests: the app's Deployment/Service/Ingress, plus a one-time cluster bootstrap (ServiceAccount, RBAC, IngressClass)
- **`.github/workflows/`** — CI/CD pipelines (below)

## CI/CD

Two independent GitHub Actions pipelines, both authenticating to AWS via OIDC — no stored credentials:

- **`terraform.yml`** — plans on every PR touching `terraform/**`; applies on merge to `main`, gated behind a manual approval
- **`app.yml`** — builds and vulnerability-scans the container image on every PR touching `app/**`; pushes to ECR and deploys to EKS on merge to `main`

## Deploying

After the first `terraform apply`, two manual one-time steps against the new cluster:

```bash
kubectl apply -f k8s/cluster-bootstrap.yaml

kubectl create secret generic starsigns-secret \
  --from-literal=MONGO_URI="mongodb://starsigns_app:$(terraform -chdir=terraform output -raw mongodb_app_password)@$(terraform -chdir=terraform output -raw mongodb_private_ip):27017/starsigns" \
  --dry-run=client -o yaml | kubectl apply -f -
```

The second step needs re-running after every `terraform apply`, since the Mongo instance's IP and password both change on redeploy.

## Intentional misconfigurations

This is a security exercise, not production code. The following are deliberate:

- MongoDB VM: outdated Linux and MongoDB versions, SSH open to `0.0.0.0/0`, IAM role with `AmazonEC2FullAccess`
- S3 backup bucket: public read and list
- App's Kubernetes ServiceAccount: bound to `cluster-admin`

AWS Config, GuardDuty, and CloudTrail are all enabled and will flag these.
