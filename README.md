The solution may be demonstrated in a variety of ways, however I took the liberty of briefly explain  the steps I took to test in my case, limiting security exposure by working in a controlled and remote environment in AWS. Also if required for someone else as well to follow the same process, for readability:
-	Launch an EC2 instance, attach an IAM role to it containing the AWS managed policies of AmazonEC2FullAccess and CloudFrontFullAccess, SSH into it, download and install the Terraform utils, create a folder “TerraformProject” and navigate into it (for tidiness in workflow), initialise Terraform then apply the document
-	Steps:
1.	Launch a t2.micro instance in region us-east-1 (N. Virginia) 
2.	Create an IAM Role with the permissions of the AWS managed policies named AmazonEC2FullAccess and CloudFrontFullAccess, and attach said role to the EC2 instance just recently launched
3.	SSH into the recently launched instance via preferred method (Guide for reference below)
	https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html 
4.	Once logged in as “ec2-user” continue with the following steps
5.	Perform the command below to manage your repositories

sudo yum install -y yum-utils

6.	Perform the command below to add the official HashiCorp Linux repository

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo 

7.	Perform the command below to install Terraform on the EC2 instance

sudo yum -y install terraform

8.	Create a working directory and navigate into it:

mkdir infra && cd infra

9.	Once in the directory create the “main.tf” file which will be used to generate the AWS environment using Terraform

nano main.tf

10.	Whilst in the file, paste the code required for Terraform as retrieved from 

https://github.com/Stefan5994/TerraformTestAND/blob/e2e552825a423dd249b76b1b6c8d70d7491ab58c/Test1%20-%20Init.tf 

11.	Initialise Terraform with terraform init and then perform terraform apply, type yes, and finally after the environment is provisioned, you will receive as output the domain name of the CloudFront distribution. With this it may be checked that the solution is performing a round robin routing across a minimum of 2 instances in different Availability Zone (as the ID’s will evidence). Located in an ASG scalable based on CPU usage, the instance may add up to a total of 6 in this particular scenario.

12.	Once demonstration is complete, feel free to command terraform destroy to terminate the environment and then terminate the instance you are using as well.


- The architecture is described within the AWS provider and exhibits a VPC containing 4 subnets (2 private, 2 public). An Auto-Scaling group is deployed to cover both public subnets and is registered with a Target Group referenced by an Application Load Balancer. The instances are launched based on the Launch Template specified in the Auto-Scaling Group configuration. Traffic is received by the ALB and forwarded to the instances within the public subnets (Security Group chaining has also been applied in order to fine-grain access to the instances specifically only from the ALB). For added security to the solution, CloudFront is provisioned in front of the architecture providing HTTPS through a default CloudFront certificate.

- The solution can be further improved by placing the instances in private subnets instead (reason why the private subnets have been actually provisioned, as a measure of future-proofing) and deploying a NAT Gateway to facilitate the instances the possibility of accessing the internet for updates and downloads. Therefore in this scenario the public subnets are envisioned to only provide the space for the ALB to provision behind the scenes (managed by AWS) the interfaces used to access the instances on their private IP addresses.

- Another potential improvement is having ownership of a Top Level Domain and managing it through Route 53 could leverage this DNS service in order to front the CloudFront distribution domain name with a human readable DNS name. Additionally it would open the solution to the benefits of Route 53 routing policies and health checks.

- With regards to Terraform itself, the current configuration is developed in a single Root Module for ease of access to frequent changes and due to relative small size of environment. However, further benefits can be drawn from decoupling elements and leveraging modules and variables alike, thus in a production environment allowing for increased agility in development overall.
