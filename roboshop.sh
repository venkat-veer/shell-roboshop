#!/usr/bin/bash

AMI_ID="ami-09c813fb71547fc4f"          # ami -id same for all siva also same
SG_ID="sg-0f80e4641e406c1e3"            # it is different siva id different mine is different.

for instance in $@
do                              # view word warp ok to get multi lines for below line
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0f80e4641e406c1e3 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    # get private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-0f7bac2de4ecca7cf --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)  
    else
        IP=$(aws ec2 describe-instances --instance-ids i-0f7bac2de4ecca7cf --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    echo "$instance:$IP"
done