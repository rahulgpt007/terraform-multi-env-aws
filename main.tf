# ---------------------------------------------------------------------------
# Data blocks: nothing is hardcoded, everything is looked up at plan time
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Name        = local.name_prefix
    Environment = var.environment
    Account     = data.aws_caller_identity.current.account_id
  }
}

# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-sg"
  description = "App security group for ${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

resource "aws_instance" "app" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = element(data.aws_subnets.default.ids, count.index)
  vpc_security_group_ids = [aws_security_group.app.id]
  monitoring             = var.enable_monitoring

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  lifecycle {
    precondition {
      condition     = var.environment == terraform.workspace
      error_message = "var.environment (${var.environment}) does not match the active workspace (${terraform.workspace}). Select the right workspace or tfvars file."
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-${count.index + 1}"
  })
}
