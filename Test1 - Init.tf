provider "aws" {
    region = "us-east-1" 
}

resource "aws_vpc" "test_vpc" {
    cidr_block = "10.5.0.0/16"
    tags = {
        Name = "TerraformTestVPC"
    }
}