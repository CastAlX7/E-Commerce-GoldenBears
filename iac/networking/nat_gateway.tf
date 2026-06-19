#Elastic IPs para los NAT Gateways (IPs públicas fijas)

resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-nat-eip-a" }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-nat-eip-b" }
}

#NAT Gateways (Puentes para subredes privadas)

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  # Dependencia explícita para asegurar que el IGW exista primero
  depends_on = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-a" }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  depends_on = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-b" }
}