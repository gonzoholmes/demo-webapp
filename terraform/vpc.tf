module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-demo-webapp"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.20.0/24", "10.0.21.0/24"]
  public_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  # Required for the ALB controller to auto-discover which subnets to place
  # load balancers in.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}