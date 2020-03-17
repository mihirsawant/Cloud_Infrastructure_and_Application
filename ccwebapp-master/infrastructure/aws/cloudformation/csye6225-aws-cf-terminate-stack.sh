#!/bin/bash
echo "Deleting stack name $1"

aws cloudformation describe-stacks --stack-name $1  --region $2 >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "Failed: Stack with  name $1 does not exist"
	exit
fi

status=$(aws cloudformation delete-stack \
--stack-name $1 --region $2)

if [ $? -eq 0 ]
then
    echo "Waiting on $1 for delete completion..."
    aws cloudformation wait stack-delete-complete --stack-name $1 --region $2
    if [ $? -eq 0 ]
    then
        echo "Stack has been Deleted"
        echo $status
    else
        echo "Failed: Failed to delete stack"
        echo $status
        exit
    fi
else
    echo "Failed: Failed to delete stack"
    echo $status
    exit
fi
