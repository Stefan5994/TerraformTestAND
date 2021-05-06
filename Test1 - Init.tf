provider "aws" {
    region = "us-east-1" 
}

resource "aws_vpc" "test_vpc" {
    cidr_block = "10.5.0.0/16"
    tags = {
        Name = "TerraformTestVPC"
    }
}

resource "aws_subnet" "priv1" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "PrivateSubnet1"
    }
}
resource "aws_subnet" "priv2" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "PrivateSubnet2"
    }
}
resource "aws_subnet" "pub1" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.3.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "PublicSubnet1"
    }
}
resource "aws_subnet" "pub2" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.4.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "PublicSubnet2"
    }
}