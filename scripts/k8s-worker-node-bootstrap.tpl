#!/bin/bash

#################################################################################################################
#here is the script to be run on the kubernetes worker nodes
#ami to be used will be the baked ami with Kubernetes pre-installations and dependencies pre-baked into the ami
#################################################################################################################

sudo systemctl restart docker
sudo systemctl enable docker

cd /

sleep 5

#creating an infinite while loop to keep searching for the "k8s-worker-script.sh" in s3 and pull when available
while :
do 
    aws s3 cp s3://pk-bucket-isaac/k8s-worker-script.sh .
    if (( $? == 0 ));
    then
    break
    fi
    sleep 5
done 

#making "k8s-worker-script.sh" script execuatable and run the script after being found
sudo chmod 777 k8s-worker-script.sh
./k8s-worker-script.sh

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767398027423.dkr.ecr.us-east-1.amazonaws.com/clixx-repository

#retrieving the load balancer address from terraform output file
load_balancer_dns=${LB_DNS}


