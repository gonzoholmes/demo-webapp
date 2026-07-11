module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "eks-demo-webapp"
  kubernetes_version = "1.33"

  # Public API open to any IP: GitHub Actions runners use unpredictable,
  # dynamic addresses, so a single-IP allowlist blocks CI's kubectl calls
  # entirely (connections time out at the network layer before auth is
  # even attempted). Actual authorization is still enforced by IAM access
  # entries + Kubernetes RBAC, not network reachability.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_ecr_repository" "ecr" {
  name                 = "ecr-demo-webapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}