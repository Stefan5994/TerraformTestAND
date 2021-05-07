provider "aws" {
    region = "us-east-1" 
}

# VPC defined below

resource "aws_vpc" "test_vpc" {
    cidr_block = "10.5.0.0/16"
    tags = {
        Name = "TestVPC_TF"
    }
}

# Subnets public and private defined below

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

# Internet Gateway defined below
resource "aws_internet_gateway" "PubIGW"{
    vpc_id = aws_vpc.test_vpc.id
    tags = {
        Name = "IGW_TF"

    }   
}

# Route Tables and route associations defined below

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
# Security group for instances provisioned from launch template - defined below

resource "aws_security_group" "LT_EC2_SG_TF" {
    description = "Allow HTTP and HTTPS traffic from any internet address"
    vpc_id = aws_vpc.test_vpc.id
    ingress {
        description = "HTTP from the Load Balancer"
        from_port = 80
        to_port = 80
        protocol = "tcp"    
        security_groups = [aws_security_group.ALB_SG.id]
    }
    ingress {
        description = "HTTPS from the Load Balancer"
        from_port = 443
        to_port = 443
        protocol = "tcp"    
        security_groups = [aws_security_group.ALB_SG.id]
    }
    egress {
        description = "All traffic to the internet"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [aws_vpc.test_vpc.cidr_block]
    }
    tags = {
        Name = "LT_EC2_SG_TF"
    }
}
# Launch template defined below

resource "aws_launch_template" "LaunchTemplate_TF" {
    name = "LT_TF"
    description = "Launch template for instances to be launched with simple text and instance ID retrieval"
    image_id = "ami-0915bcb5fa77e4892"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.LT_EC2_SG_TF.id]
    user_data = "${base64encode(data.template_file.User_Data_TempFile.rendered)}"

    }

data "template_file" "User_Data_TempFile" {
  template = <<EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl start httpd
    systemctl enable httpd
    cd /var/www/html
    InstID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    AZID=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1> This is IntsanceID </h1>" > index.txt
  EOF
}

# Autoscaling group defined below 

 resource "aws_autoscaling_group" "ASGTest" {
    min_size = 2
    max_size = 2
    vpc_zone_identifier = [aws_subnet.priv1.id,aws_subnet.priv2.id]
    target_group_arns = [aws_lb_target_group.ALB_TG_TF.id]z
    launch_template {
        id = aws_launch_template.LaunchTemplate_TF.id
        version = aws_launch_template.LaunchTemplate_TF.latest_version
    }
}

# Application Load Balancer defined below including corresponding Security Group

resource "aws_security_group" "ALB_SG" {
    description = "Allow HTTP and HTTPS traffic from any internet address"
    vpc_id = aws_vpc.test_vpc.id
    ingress {
        description = "HTTPS from the internet"
        from_port = 443
        to_port = 443
        protocol = "tcp"    
        cidr_blocks = ["0.0.0.0/0"]
    }   
    ingress {
        description = "HTTP from the internet"
        from_port = 80
        to_port = 80
        protocol = "tcp"    
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "All traffic to the internet"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    
    tags = {
        Name = "ALB_SG_TF"
    }
}
resource "aws_lb_target_group" "ALB_TG_TF" {
    name = "TargetGroup-TF"
    vpc_id = aws_vpc.test_vpc.id
    port = 80
    protocol = "HTTP"
    
}
resource "aws_lb_listener" "ALB_Listener_TF" {
    load_balancer_arn = aws_lb.alb-TF.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.ALB_TG_TF.id
    }
}
resource "aws_lb" "alb-TF" {
    name = "ALB-TF"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.ALB_SG.id]
    subnets = [aws_subnet.pub1.id,aws_subnet.pub2.id]

}

