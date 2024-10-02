provider "aws" {
  region = "ap-southeast-1"

}

#This is VPC code

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}

# this is Subnet code
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.test-vpc.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = "10.0.0.0/24"

  tags = {
    Name = "Public-subnet"
  }
}


resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.test-vpc.id
  availability_zone = "ap-southeast-1b"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "Private-subnet" #security group
  }
}
resource "aws_security_group" "test_access" {
  name        = "test_access"
  vpc_id      = aws_vpc.test-vpc.id
  description = "allow ssh and http"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
#security group end here#internet gateway code
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "test-igw"
  }
}


#Public route table code

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-igw.id
  }


  tags = {
    Name = "public-rt"

  }
}
#route Tatable assosication code
resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}
#ec2 code
resource "aws_instance" "JD-server" {
  ami             = "ami-0aa097a5c0d31430a"
  subnet_id       = aws_subnet.public-subnet.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_access.id}"]
  key_name        = "DEVARAKEY"
  tags = {
    Name     = "test-World"
    Stage    = "testing"
    Location = "chennai"
  }

}


##create an EIP for EC2
resource "aws_eip" "jdETP" {
  instance = aws_instance.JD-server.id
}


###this is database ec2 code
resource "aws_instance" "JDB-server" {
  ami             = "ami-0aa097a5c0d31430a"
  subnet_id       = aws_subnet.private-subnet.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.test_access.id}"]
  key_name        = "DEVARAKEY"
  tags = {
    Name     = "db-World"
    Stage    = "stage-base"
    Location = "delhi"
  }

}
##create a public ip for Nat gateway
resource "aws_eip" "nat-eip" {
}
### create Nat gateway
resource "aws_nat_gateway" "my-ngw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnet.id
}

#create private route table
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-ngw.id
  }


  tags = {
    Name = "private-rt"
  }
}
##route Tatable assosication code
resource "aws_route_table_association" "private-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}
