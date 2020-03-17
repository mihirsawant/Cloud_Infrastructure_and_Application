#!/bin/bash

# creation of network resources


echo "Enter your region"
read awsRegion

echo "Enter a name for your VPC"
read myVpc
echo "Enter a cidr block you wish for your VPC"
read myVpcCidrBlock
echo "No of Subnets required"
read number



declare -a subnet_cidrArray
echo "Enter CidrBlocks for your subnets"

for(( i = 0; i < $number ; i++ ))
do
 echo "Subnet$(( i+1 )) CidrBlock:"
 read cidr
 subnet_cidrArray[$i]="$cidr"
done


vpcId=$(aws --region $awsRegion ec2 create-vpc --cidr-block $myVpcCidrBlock --instance-tenancy default --output text --query 'Vpc.VpcId' 2> /dev/null)
if [ $? -ne 0 ]
then
 echo "Failure: The Cidr Block you entered is not valid"
 exit
fi
$(aws --region $awsRegion ec2 create-tags --resources $vpcId --tags Key=Name,Value=$myVpc)
$(aws --region $awsRegion ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support)
$(aws --region $awsRegion ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames)

echo "$myVpc Created VPC "

declare -a subnetIds
a=0
while [ $a -lt $number ]
do
 subnetId=$(aws --region $awsRegion ec2 create-subnet --vpc-id $vpcId --cidr-block ${subnet_cidrArray[$a]}\
 --output text --query 'Subnet.SubnetId' 2> /dev/null)
 subnetIds[$a]=$subnetId
 if [ $? -ne 0 ]
 then
 echo "Failure: coudn't create $myVpc-Subnet$(( a+1 ))"
 exit
 fi

 aws --region $awsRegion ec2 create-tags --resources ${subnetIds[$a]} --tags Key=Name,Value="$myVpc-Subnet${a+1}"
 echo "$myVpc-Subnet$(( a+1 )) Created subnets"

 (( a++ ))
done



igwId=$(aws --region $awsRegion ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId' 2> /dev/null)
if [ $? -ne 0 ]
then
 echo "Failure: coudn't create $myVpc-IGW"
 exit
fi
aws --region $awsRegion ec2 create-tags --resources $igwId --tags Key=Name,Value="$myVpc-IGW"
echo "$myVpc-IGW Created internet-gateway"


aws --region $awsRegion ec2 attach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId 2> /dev/null
if [ $? -ne 0 ]
then
 echo "Failure: Could not attach $myVpc-IGW to your $myVpc"
 exit
fi
echo "$myVpc-IGW Attachment to $myVpc Completed attaching"




routeTableId=$(aws --region $awsRegion ec2 create-route-table --vpc-id $vpcId --output text --query 'RouteTable.RouteTableId' 2> /dev/null)
if [ $? -ne 0 ]
then
 echo "Failure: coudn't create Route Table with the name $myVpc-RouteTable"
 exit
fi
aws --region $awsRegion ec2 create-tags --resources $routeTableId --tags Key=Name,Value="$myVpc-RouteTable"
echo "$myVpc-RouteTable Created"

for (( i=0; i<${#subnetIds[@]} ; i++ ))
do
 associationId=$(aws --region $awsRegion ec2 associate-route-table --subnet-id ${subnetIds[$i]} --route-table-id $routeTableId\
 --output text --query 'AssociationId' 2> /dev/null)
 if [ -z $associationId ]
 then
 echo "Failure: coudn't associate Subnet-$(( i+1 )) to $myVpc-RouteTable"
 exit
 fi
 echo "Associated $myVpc-Subnet$(( i+1 )) to $myVpc-RouteTable"
done


status=$(aws --region $awsRegion ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId \
--output text --query 'Return' 2> /dev/null)
if [ "$status" = "False" ]
then
 echo "Failure: coudn't add Route 0.0.0.0/0 to your $myVpc-RouteTable"
 exit
fi
echo "Route 0.0.0.0/0 add to $myVpc-RouteTable"


echo "Stack created Successfully"






