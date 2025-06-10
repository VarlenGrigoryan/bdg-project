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
    values = ["eu-west-1b"]  # Adjust to a valid AZ if needed
}
}

resource "aws_instance" "web" {
  ami           = "ami-00425bfa541862e69"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default.id
  tags = {
    Name = "varlens-web-instance"
  }
}

