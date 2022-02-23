terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-c7-assignment"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "C7resource"
  }
}
resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = "vpc-0381f0b9bbde6c67f"

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["122.162.48.196/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh"
  }
}
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "bastion-instance"

  ami                    = "ami-04505e74c0741db8d"
  instance_type          = "t2.micro"
  key_name               = "Final Assignment"
  monitoring             = true
  vpc_security_group_ids = [resource.aws_security_group.ssh.id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Allow all inbound traffic"
  vpc_id      = "vpc-0381f0b9bbde6c67f"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins"
  }
}
resource "aws_security_group" "App" {
  name        = "App"
  description = "Allow incoming to port 80 from self"
  vpc_id      = "vpc-0381f0b9bbde6c67f"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App"
  }
}
module "Jenkins_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "Jenkins-instance"

  ami                    = "ami-04505e74c0741db8d"
  instance_type          = "t2.micro"
  key_name               = "Final Assignment"
  monitoring             = true
  vpc_security_group_ids = [resource.aws_security_group.jenkins.id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
module "App_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "App-instance"

  ami                    = "ami-04505e74c0741db8d"
  instance_type          = "t2.micro"
  key_name               = "Final Assignment"
  monitoring             = true
  vpc_security_group_ids = [resource.aws_security_group.App.id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
