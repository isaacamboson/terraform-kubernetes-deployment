#!/bin/bash

sudo su - ec2-user
# sudo su -

#Downloading PEM Key from S3
aws s3 cp s3://${s3_bucket}/${pem_key} /home/ec2-user/${pem_key}
# aws s3 cp s3://${s3_bucket}/${pem_key} /root/${pem_key}

#changing permission of pem key
chmod 400 /home/ec2-user/${pem_key}
# chmod 400 /root/${pem_key}

sudo yum update -y
# sudo yum install -y nfs-utils

