# ce_cherbao_module2.6/main.tf

provider "aws" {
  region = var.region
}

# Local variables for common tags
locals {
  common_tags = {
    Environment = "Dev"
    Project     = "ce10-cherbao"
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, {
    Name = "laoniu-main-vpc"
  })
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "laoniu-main-igw"
  })
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "laoniu-public-subnet"
  })
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.azs[1]

  tags = merge(local.common_tags, {
    Name = "laoniu-private-subnet"
  })
}

# Create Database Subnet
resource "aws_subnet" "database" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr
  availability_zone = var.azs[2]

  tags = merge(local.common_tags, {
    Name = "laoniu-database-subnet"
  })
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "laoniu-main-nat-gateway"
  })
}

# Allocate Elastic IP for NAT
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  depends_on = [aws_internet_gateway.igw]

  tags = merge(local.common_tags, {
    Name = "laoniu-nat-eip"
  })
}

# Creating Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "laoniu-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Creating Private Route Table (if using NAT gateway)
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(local.common_tags, {
    Name = "laoniu-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private[0].id
}

# Retrieve latest Amazon Linux 2 AMI ID
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Security Group to allow SSH
resource "aws_security_group" "ssh_sg" {
  name        = "ce10-laoniu-sgp"      # Change the security group name
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "ce10-laoniu-sgp"      # Change the security group name
  })
}

# Create EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.dynamodb_read_profile.name

  tags = merge(local.common_tags, {
    Name = "ce10-laoniu-ec2instance"
  })
}

# Create DynamoDB Table
resource "aws_dynamodb_table" "book_inventory" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ISBN"
  range_key    = "Genre"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = var.dynamodb_table_name
  })
}

# Create IAM Policy to enable read and write
resource "aws_iam_policy" "dynamodb_read" {
  name        = "cherbao-dynamodb-read"
  description = "Policy to allow all list and read actions on DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ],
        Resource = aws_dynamodb_table.book_inventory.arn
      }
    ]
  })
}

# Create IAM Role for EC2
resource "aws_iam_role" "dynamodb_read_role" {
  name = "cherbao-dynamodb-read-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policy to Role
resource "aws_iam_role_policy_attachment" "dynamodb_read_attachment" {
  role       = aws_iam_role.dynamodb_read_role.name
  policy_arn = aws_iam_policy.dynamodb_read.arn
}

# Create Instance Profile
resource "aws_iam_instance_profile" "dynamodb_read_profile" {
  name = "cherbao-dynamodb-read-profile"
  role = aws_iam_role.dynamodb_read_role.name
}
