terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "5.74.0"
        }
    }
}

provider "aws" {
  # Configuration options
}

module "vpc" {
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=12caf8056992a6e327c584475f1522d05e77284d"
    version = "5.14.0"

    name = "my-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-west-2a"]
    private_subnets = ["10.0.1.0/24"]
    public_subnets  = ["10.0.101.0/24"]

    enable_nat_gateway = true

    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}

module "public_sg" {
    source  = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=43798eab255616bd23ef4140f50252d585c9c51b"
    version = "5.2.0"

    name        = "public-sg"
    description = "Security group for public subnet"
    vpc_id      = module.vpc.vpc_id

    ingress_with_cidr_blocks = [
        {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = "0.0.0.0/0"
        }
    ]
    egress_with_cidr_blocks = [
        {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = "0.0.0.0/0"
        }
    ]
}

module "private_sg" {
    source  = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=43798eab255616bd23ef4140f50252d585c9c51b"
    version = "5.2.0"

    name        = "pritave-sg"
    description = "Security group for public subnet"
    vpc_id      = module.vpc.vpc_id

    ingress_with_self = [
        {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
        }
    ]
    egress_with_cidr_blocks = [
        {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = "0.0.0.0/0"
        }
    ]
}

module "public_ec2" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=6f851d84fd878cb75b88921e328eaf8ce26c7343"
  version = "5.7.1"

  name = "public_ec2"

  instance_type          = "t2.micro"
  monitoring             = true
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_sg.security_group_id]
  associate_public_ip_address = true

  tags = {
    Name = "public_instance"
  }
}

module "private_ec2" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=6f851d84fd878cb75b88921e328eaf8ce26c7343"
  version = "5.7.1"

  name = "private_ec2"

  instance_type          = "t2.micro"
  monitoring             = true
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.private_sg.security_group_id]

  tags = {
    Name = "private_instance"
  }
}

