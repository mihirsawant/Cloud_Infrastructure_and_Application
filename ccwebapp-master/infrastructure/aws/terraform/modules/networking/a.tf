
variable "Vpc_Region"{
    type=string
    default="us-east-1"
}
variable "Vpc_Name"{
    type=string
    default="VPC"
}
variable "cidr_block"{
    type=string
    default="10.0.2.0/16"
}

provider "aws" {
    region =var.Vpc_Region
}

#terraform apply -var="cidr_block= 10.0.0.0/16"

variable "subnets" {
    
  type = list(string)
  }



 resource "aws_vpc" "VPN_1"{
     
     cidr_block= "${var.cidr_block}"
     enable_dns_hostnames= true
     enable_dns_support= true
     enable_classiclink_dns_support= true
     assign_generated_ipv6_cidr_block=false
     tags={
         Name= var.Vpc_Name
     }
 }
output "VPN_1"{
    value="${aws_vpc.VPN_1.id}"
}

 resource "aws_subnet" "subnet1" {
     count= "${length(var.subnets)}"
     
    cidr_block="${element((var.subnets), count.index)}"
     vpc_id="${aws_vpc.VPN_1.id}"
    #  availability_zone="us-east-1a"
     map_public_ip_on_launch=true
     tags={
         Name= "Subnet"
     }
 }
 output "SUBNET"{
    value="${aws_subnet.subnet1[0].id}"
}
 output "SUBNET1"{
    value="${aws_subnet.subnet1[1].id}"
}
 output "SUBNET2"{
    value="${aws_subnet.subnet1[2].id}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.VPN_1.id}"

  tags = {
    Name = "main_GateWay"
  }
}
resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.VPN_1.id}"
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
tags= {
    Name="Terraform-Route"
}
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet1[0].id}"
  route_table_id = "${aws_route_table.route-table.id}"
}



