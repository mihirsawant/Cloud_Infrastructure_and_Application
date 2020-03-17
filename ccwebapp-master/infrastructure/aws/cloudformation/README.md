**VPC using CloudFormation**


1. Create a Virtual Private CLoud (VPC)
2. Create 3 subnets according to the requirements in the VPC with each in different availability zones
3. Create a Internet Gateway 
4. Attach the Internet Gateway to VPC
5. Create a Public Route-Table and attach all the 3 subnets to the Route-Table
6. Create a public Route in the Public Route-Table with Destination Cidr BLock of 0.0.0.0/0 and connect to internet gateway as well.

**AWS CLI SETUP**
1. Install AWS CLI
2. Run aws configure command and enter all credentials.
3. Enter dev and prod credentials and configuration

**Creation of VPC**

* *DESCRIPTION* * :
Run csye6225-aws-cf-create-stack.sh shell script to create VPC
Command line arguments passed :
AWS region
VPC CIDR block
Subnet CIDR block
VPC name

Steps to Run:
Command : ``` sh csye6225-aws-cf-create-stack.sh <stackname> <vpcName> <awsRegion> <vpcCidrBlock> <Subnet1CidrBlock> <Subnet2CidrBlock> <Subnet3Block>```

Example  : ```sh csye6225-aws-cf-create-stack.sh newStack newVPC us-east-1 10.0.0.0/16 10.0.0.0/18 10.0.64.0/18 10.0.128.0/17```

command line arguments passed signifies the following :

newStack -      Stack name for stack Creation
newVPC -        VPC name 
us-east-1 -     AWS Region where the VPC shoud be created
10.0.0.0/16 -   VPC CIDR block
10.0.0.0/18 -   VPC Subnet 1 CIDR block
10.0.64.0/18 -  VPC Subnet 2 CIDR block
10.0.128.0/17 - VPC Subnet 3 CIDR block


**Deletion of VPC using CloudFormation**

* *DESCRIPTION* *:
Run csye6225-aws-cf-terminate-stack.sh script to delete the VPC
Command line arguments passed :
Stack Name
AWS Region

Steps to Run:
Command : ```csye6225-aws-cf-terminate-stack.sh <stackName> <awsRegion>```

Example  : ```sh csye6225-aws-cf-terminate-stack.sh newStack us-east-1```


command line arguments passed signifies the following :

newStack -  Stack name that should be deleted
us-east-1 - AWS region from where it should be delted








