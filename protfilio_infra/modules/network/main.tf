resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-VPC"})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-IGW"})
  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.user_name}-${each.key}-public-subnet"
  })

  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name_prefix}-${var.user_name}-public-rt"
  }
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [
    aws_route_table.public
  ]
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
  depends_on = [
    aws_route_table.public
  ]
}
