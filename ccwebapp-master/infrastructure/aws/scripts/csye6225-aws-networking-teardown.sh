#!/bin/bash

#final one 
echo "Tearing down network resources"

VPC_ID="$1";
AWS_REGION="$2";
if [ -z "$VPC_ID" ]
then
	echo "Please provide a VPC"
	exit 0
fi

vpc=$(aws --region $AWS_REGION ec2 describe-vpcs --filters Name=vpc-id,Values="$VPC_ID" --output text)
if [ -z "$vpc" ]
then
	echo "$VPC_ID This VPC does not exist"
	exit 0
fi

#Finding Route Table ID
route_table_id=$(aws --region $AWS_REGION ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=false --query 'RouteTables[*].{RouteTableId:RouteTableId}' --output text)
status=$?
if [ $status -ne 0 ];
then
	echo "Incorrect Route Table ID"
        exit $status
fi

#Finding Internet Gateway ID
internet_gateway_id=$(aws --region $AWS_REGION ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" --query 'InternetGateways[*].{InternetGatewayId:InternetGatewayId}' --output text)
status=$?
if [ $status -ne 0 ];
then
        echo "Incorrect Internet Gateway ID"
        exit $status
fi

#Deleting Subnets in the VPC
subnets=$(aws --region $AWS_REGION ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
status=$?
if [ $status -ne 0 ]
then
       	echo "Could not find subnets"
    	exit $status
fi
for subnet_id in $subnets
do
    aws --region $AWS_REGION ec2 delete-subnet --subnet-id $subnet_id
	status=$?
	if [ $status -ne 0 ];
	then
        	echo "Incorrect Subnet ID $subnet_id"
        	exit $status
	fi
	echo "Deleted the subnet $subnet_id"
done

#Deleting Route Table
aws --region $AWS_REGION ec2 delete-route-table --route-table-id $route_table_id
status=$?
if [ $status -ne 0 ];
then
        echo "Incorrect Route Table ID $route_table_id"
        exit $status
fi
echo "Deleted the route table $route_table_id"

#Detaching Internet Gateway
aws --region $AWS_REGION ec2 detach-internet-gateway --internet-gateway-id $internet_gateway_id --vpc-id $VPC_ID
status=$?
if [ $status -ne 0 ];
then
        echo "Detaching Internet Gateway $internet_gateway_id"
        exit $status
fi
echo "Detached the internet gateway $internet_gateway_id"

#Deleting Internet Gateway
aws --region $AWS_REGION ec2 delete-internet-gateway --internet-gateway-id $internet_gateway_id
status=$?
if [ $status -ne 0 ];
then
        echo "Incorrect Internet Gateway ID $internet_gateway_id"
        exit $status
fi
echo "Deleted teh internet gateway $internet_gateway_id"

#Deleting VPC
aws --region $AWS_REGION ec2 delete-vpc --vpc-id $VPC_ID
status=$?
if [ $status -ne 0 ];
then
        echo "Could not delete the VPC $vpc"
        exit $status
fi
echo "Deleted the VPC $VPC_ID"
echo "Network teardown successfully done"
