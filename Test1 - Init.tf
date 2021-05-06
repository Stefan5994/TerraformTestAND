provider "aws" {
    region = "us-east-1" 
}

resource "aws_vpc" "test_vpc" {
    cidr_block = "10.5.0.0/16"
    tags = {
        Name = "TestVPC_TF"
    }
}

resource "aws_subnet" "priv1" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "PrivateSubnet1_TF"
    }
}
resource "aws_subnet" "priv2" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "PrivateSubnet2_TF"
    }
}
resource "aws_subnet" "pub1" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.3.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "PublicSubnet1_TF"
    }
}
resource "aws_subnet" "pub2" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.4.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "PublicSubnet2_TF"
    }
}

resource "aws_internet_gateway" "PubIGW"{
    vpc_id = aws_vpc.test_vpc.id
    tags = {
        Name = "IGW_TF"

    }   
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.test_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.PubIGW.id
    }

    tags = {
        Name = "PublicRouteTable_TF"
    }
}

resource "aws_route_table_association" "PubRoutAssoc1" {
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.pub1.id
}

resource "aws_route_table_association" "PubRoutAssoc2" {
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.pub2.id
}

resource "aws_route_table" "private_route" {
    vpc_id = aws_vpc.test_vpc.id
    tags = {
        Name = "PrivateRouteTable_TF"
    }
}

resource "aws_route_table_association" "PrivRoutAssoc1" {
    route_table_id = aws_route_table.private_route.id
    subnet_id = aws_subnet.priv1.id
}

resource "aws_route_table_association" "PrivRoutAssoc2" {
    route_table_id = aws_route_table.private_route.id
    subnet_id = aws_subnet.priv2.id
}