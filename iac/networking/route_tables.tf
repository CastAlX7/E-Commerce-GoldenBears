#1. Tabla Pública (Public-RT)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

#2. Tablas Privadas de Aplicación (RT-1a y RT-1b)
resource "aws_route_table" "app_a" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = { Name = "${var.project_name}-app-rt-a" }
}

resource "aws_route_table" "app_b" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  tags = { Name = "${var.project_name}-app-rt-b" }
}

#3. Tabla Aislada (Private-Isolated-RT)
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.project_name}-isolated-rt" }
}

#4. Asociaciones (Aquí amarramos las subredes a sus tablas)

# Asociaciones Públicas
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Asociaciones App (donde viven ECS y Endpoints)
resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.app_a.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.app_b.id
}

# Asociaciones Aisladas (DBs, Ingress, Lambda)
resource "aws_route_table_association" "iso_ingress_a" {
  subnet_id      = aws_subnet.private_ingress_a.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "iso_ingress_b" {
  subnet_id      = aws_subnet.private_ingress_b.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "iso_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "iso_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "iso_lambda" {
  subnet_id      = aws_subnet.private_lambda_a.id
  route_table_id = aws_route_table.isolated.id
}