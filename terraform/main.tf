provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["eu-west-1b"]  
}
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/deployer-new-key.pub")
}

resource "aws_instance" "web" {
  ami           = "ami-0286d0aea4d6c7a34"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = data.aws_subnet.default.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "varlens-web-instance"
  }
}

resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

terraform {
  backend "s3" {
    bucket = "varlens-terraform-bucket"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

