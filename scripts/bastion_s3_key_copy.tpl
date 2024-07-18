#!/bin/bash

sudo su - ec2-user
# sudo su -

#Downloading PEM Key from S3
aws s3 cp s3://${s3_bucket}/${pem_key} /home/ec2-user/${pem_key}

#changing permission of pem key
chmod 400 /home/ec2-user/${pem_key}

sudo yum update -y


