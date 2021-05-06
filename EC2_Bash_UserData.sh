#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd
cd /var/www/html
InstID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
AZID=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<h1> This is IntsanceID </h1>" > index.txt
echo "<h1> Welcome to the demo functionality of Terraform, served from instance $InstID located in availability zone $AZID </h1>" > index.html
# sed "s/INSTANCE/$EC2NAME/" index.txt > index.html
