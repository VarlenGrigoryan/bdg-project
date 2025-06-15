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
  public_key = file("~/.ssh/bdg-key.pub")
}

resource "aws_instance" "web" {
  ami           = "ami-0286d0aea4d6c7a34"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = data.aws_subnet.default.id
  tags = {
    Name = "varlens-web-instance"
  }
}

terraform {
  backend "s3" {
    bucket = "varlens-terraform-bucket"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

