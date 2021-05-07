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
resource "aws_subnet" "priv3" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.3.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "PrivateSubnet3_TF"
    }
}
resource "aws_subnet" "pub1" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.4.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "PublicSubnet1_TF"
    }
}
resource "aws_subnet" "pub2" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.5.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "PublicSubnet2_TF"
    }
}
resource "aws_subnet" "pub3" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.5.6.0/24"
    availability_zone = "us-east-1c"
    map_public_ip_on_launch = true
    tags = {
        Name = "PublicSubnet3_TF"
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

resource "aws_route_table_association" "PubRoutAssoc3" {
    route_table_id = aws_route_table.public_route.id
    subnet_id = aws_subnet.pub3.id
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

resource "aws_route_table_association" "PrivRoutAssoc3" {
    route_table_id = aws_route_table.private_route.id
    subnet_id = aws_subnet.priv3.id
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
    #ingress {
     #   description = "SSH from the Internet for EC2 Connect"
      #  from_port = 22
       # to_port = 22
        #protocol = "tcp"    
        #cidr_blocks = ["0.0.0.0/0"]
    #}
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
        cidr_blocks = ["0.0.0.0/0"]
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
#!/bin/sh
yum -y install httpd php
chkconfig httpd on
systemctl start httpd.service
cd /var/www/html
wget https://s3-us-west-2.amazonaws.com/us-west-2-aws-training/awsu-spl/spl-03/scripts/examplefiles-elb.zip
unzip examplefiles-elb.zip
  EOF
}

# Autoscaling group defined below 

 resource "aws_autoscaling_group" "ASGTest" {
    min_size = 2
    max_size = 6
    vpc_zone_identifier = [aws_subnet.pub1.id,aws_subnet.pub2.id,aws_subnet.pub3.id]
    target_group_arns = [aws_lb_target_group.ALB_TG_TF.id]
    launch_template {
        id = aws_launch_template.LaunchTemplate_TF.id
        version = aws_launch_template.LaunchTemplate_TF.latest_version
    }

}

resource "aws_autoscaling_policy" "TargetTrackingPolicy_TF" {
    name = "ASG_TargetTrackingPolicy_TF"
    autoscaling_group_name = aws_autoscaling_group.ASGTest.name
    policy_type = "TargetTrackingScaling"
    target_tracking_configuration {
    predefined_metric_specification {
    predefined_metric_type = "ASGAverageCPUUtilization"
    }
        target_value = 75.0
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
    subnets = [aws_subnet.pub1.id,aws_subnet.pub2.id,aws_subnet.pub3.id]

}

# CloudFront distribution configured below for HTTP redirection to HTTPS and increased security and performance

resource "aws_cloudfront_distribution" "CFront_TF" {
  origin {
    domain_name = aws_lb.alb-TF.dns_name
    origin_id   = aws_lb.alb-TF.id
    custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols = ["TLSv1"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
#  comment             = "Some comment"
  default_root_object = "index.php"

  default_cache_behavior {
    forwarded_values {
        query_string = false

    cookies {
        forward = "none"
      }
    }  
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.alb-TF.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_100"


  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Name = "CloudFront_TF"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "CloudFront_Domain_Name" {
  value = aws_cloudfront_distribution.CFront_TF.domain_name
}