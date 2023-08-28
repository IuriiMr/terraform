resource "aws_vpc" "iuriimr_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "iuriimr_subnet" {
  vpc_id                  = aws_vpc.iuriimr_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "dev-subnet"
  }
}

resource "aws_internet_gateway" "iuriimr_igw" {
  vpc_id = aws_vpc.iuriimr_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "iuriimr_route_table" {
  vpc_id = aws_vpc.iuriimr_vpc.id

  tags = {
    Name = "dev-route-table"
  }
}

resource "aws_route" "iuriimr_route" {
  route_table_id         = aws_route_table.iuriimr_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.iuriimr_igw.id
}

resource "aws_route_table_association" "iuriimr_route_table_association" {
  subnet_id      = aws_subnet.iuriimr_subnet.id
  route_table_id = aws_route_table.iuriimr_route_table.id
}

resource "aws_security_group" "iuriimr_security_group" {
  name        = "dev-sg"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.iuriimr_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "iuriimr_key_pair" {
  key_name   = "dev-key"
  public_key = file("~/.ssh/aws_ubuntu_key.pub")
}

resource "aws_instance" "dev_node" {
  ami                    = data.aws_ami.ubuntu_server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.iuriimr_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.iuriimr_security_group.id]
  subnet_id              = aws_subnet.iuriimr_subnet.id
  user_data              = file("userdata.tpl")

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("sshconfig.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/aws_ubuntu_key"
    })
    interpreter = ["bash", "-c"]
  }

}
