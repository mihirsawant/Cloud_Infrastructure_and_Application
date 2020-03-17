variable "Vpc_Region"{
    type=string
    default="us-east-1"
}
variable "Vpc_Name"{
    type=string
    default="VPC"
}
variable "APP"{
    type=string
    default="VPC"
}
variable "cidr_block"{
    type=string
    default="10.0.2.0/16"
}
variable "KeyName"{
    type=string
    default="10.0.2.0/16"
}
variable "CodedeployS3Bucket"{
  type=string
  default="us-east-1"
}
variable "ImageS3Bucket"{
  type=string
  default="us-east-1"
}

variable "subnets" {
    type = list(string)
    default=["10.8.1.0/24", "10.8.2.0/24", "10.8.3.0/24"]
  }
variable "AMI"{
    type=string
    default="us-east-1"
}
variable "AWS_ACCESS_KEY_ID"{
    type=string
    default="us-east-1"
}
variable "AWS_SECRET_ACCESS_KEY"{
    type=string
    default="us-east-1"
}

variable "Account_id"{
    type=string
    default="us-east-1"
}
variable "LambdaBucket"{
  type=string
  default="lambda.meetveera.me"
}
variable "Domain"{
    type=string
    default="us-east-1"
}
variable "Zone_id"{
  type=string
  default="us-east-1"
}
variable "Identifier"{
  type=string
  default="us-east-1"
}


module "networking" {
  source = "./networking"
  Vpc_Region="${var.Vpc_Region}"
  Vpc_Name="${var.Vpc_Name}"
  cidr_block="${var.cidr_block}"
  subnets="${var.subnets}"
 }
module "application" {
  source = "./application"
  Vpc_Name="${var.Vpc_Name}"
  Vpc_Region="${var.Vpc_Region}"
  cidr_block="${var.cidr_block}"
  Vpc_id=module.networking.VPN_1
  SUBNET=module.networking.SUBNET
  SUBNET1=module.networking.SUBNET1
  SUBNET2=module.networking.SUBNET2
  AMI="${var.AMI}"
  Domain="${var.Domain}"
  Zone_id="${var.Zone_id}"
  Identifier="${var.Identifier}"
  KeyName="${var.KeyName}"
  CodedeployS3Bucket="${var.CodedeployS3Bucket}"
  ImageS3Bucket="${var.ImageS3Bucket}"
  AWS_SECRET_ACCESS_KEY="${var.AWS_SECRET_ACCESS_KEY}"
  AWS_ACCESS_KEY_ID="${var.AWS_ACCESS_KEY_ID}"
  Account_id="${var.Account_id}"
  LambdaBucket="${var.LambdaBucket}"
}
