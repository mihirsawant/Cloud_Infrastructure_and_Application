# Terraform

## Installation
Download Terraform single binary file from the below link<br>
https://www.terraform.io/downloads.html <br>

## Setup
For User to able to make changes to your AWS account AWS_PROFILE should be set for IAM user as environment variables by the following commands<br>

export AWS_ACCESS_KEY =(your access key)<br>
export AWS_SECRET_KEY =(your secret access key)<br>

### Steps
terraform init<br>
terraform plan<br>
terraform apply [variables and cidr blocks]<br>
terraform destroy<br>
### Explanation<br>
export AWS_PROFILE = (env variable) -> to set the Profile for the current terraform session<br>
terraform init -> tells Terraform to scan the code and read the providers to be downloaded for the execution<br>
terraform plan -> to perform a refresh and create an execution plan<br>
terraform apply -> to create the required cidr blocks/vpcs and subnets<br>
terraform destroy -> destroys the mentioned vpc or subnet block<br>
