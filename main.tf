data "aws_availability_zones" "az" {
  state = "available"
}

# Create resource group
resource "aws_resourcegroups_group" "rg" {
  name        = var.resource_group_name
  description = "Resource Group for ${var.resource_tags.use_case}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "owner",
          "Values": [
            "${var.resource_tags.owner}"
          ]
        },
        {
          "Key": "use_case",
          "Values": [
            "${var.resource_tags.use_case}"
          ]
        }
      ]
    }
    JSON
  }
}

# Create vpc resources
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = "vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.az.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_nat_gateway = false
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.resource_tags
}

# Create app security group
module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name        = "web-sg"
  description = "Security group for web-servers with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  #   ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks
  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = var.resource_tags
}

# Create lb security group
module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name        = "lb-sg"
  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = var.resource_tags
}

# Get image ami
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Generate random number
resource "random_pet" "app" {
  length    = 2
  separator = "-"
}

# Create lb 
resource "aws_lb" "app" {
  name               = "main-app-${random_pet.app.id}-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [module.lb_security_group.this_security_group_id]

  tags = var.resource_tags
}

# Create lb listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
    # forward {
    #   target_group {
    #     arn    = aws_lb_target_group.blue.arn
    #     weight = lookup(local.traffic_dist_map[var.traffic_distribution], "blue", 100)
    #   }

    #   target_group {
    #     arn    = aws_lb_target_group.green.arn
    #     weight = lookup(local.traffic_dist_map[var.traffic_distribution], "green", 0)
    #   }

    #   stickiness {
    #     enabled  = false
    #     duration = 1
    #   }
    # }
  }

  tags = var.resource_tags
}
