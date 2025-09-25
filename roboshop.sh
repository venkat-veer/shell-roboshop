#!/usr/bin/bash

AMI_ID="ami-09c813fb71547fc4f"          # ami -id same for all siva also same
SG_ID="sg-0f80e4641e406c1e3"            # it is different siva id different mine is different.
ZONE_ID="Z05359301W668SBI8XW8V"         # hosted-zone id of mine differ for every one.
DOMAIN_NAME="devaws.store"

for instance in $@
do                              # view word warp ok to get multi lines for below line
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    # get private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)  
        RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.devaws.store
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME"           #devaws.store
    fi

    echo "$instance:$IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \	    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
	    }
		}]
    }
	'
done