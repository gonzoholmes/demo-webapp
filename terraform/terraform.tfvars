aws_region  = "us-east-1"
environment = "Production"

vpc_cidr               = "10.0.0.0/16"
private_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]
public_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
mongodb_instance_type  = "t3.micro"
mongodb_ami_id         = "ami-05ffe3c48a9991133"
eks_kubernetes_version = "1.33"
