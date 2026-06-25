#Subredes Públicas (Para NAT Gateways)

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false 

  tags = {
    Name = "${var.project_name}-public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-public-subnet-b"
  }
}

#Subredes Privadas de Ingress (Para ALB Interno y VPC Link)

resource "aws_subnet" "private_ingress_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.project_name}-private-ingress-subnet-a"
  }
}

resource "aws_subnet" "private_ingress_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.project_name}-private-ingress-subnet-b"
  }
}

# Subredes Privadas de Aplicación (Para ECS, ElastiCache y Endpoints)
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.project_name}-private-app-subnet-a"
  }
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.project_name}-private-app-subnet-b"
  }
}

#Subredes Privadas de Base de Datos (Para Aurora)
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.project_name}-private-db-subnet-a"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.project_name}-private-db-subnet-b"
  }
}

#Subred Privada Aislada (Para Lambda de Inventario)
resource "aws_subnet" "private_lambda_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.project_name}-private-lambda-subnet-a"
  }
}