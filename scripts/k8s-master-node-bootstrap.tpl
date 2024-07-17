#!/bin/bash

cd /

#################################################################################################################
#here is the script to be run on the kubernetes master node
#ami to be used will be the baked ami with Kubernetes pre-installations and dependencies pre-baked into the ami
#################################################################################################################

#removing a previous version of script running "kubeadm join" to be used on worker nodes, from s3
aws s3 rm s3://pk-bucket-isaac/k8s-worker-script.sh

sudo systemctl restart docker
sudo systemctl enable docker

sleep 10

#obtaining the private ip of the master node grep the "ip -4 addr" command with a regular expression
private_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# "kubeadm" will create the cluster, "--pod-network-cidr" will determine what the pod network will be used. 
# "--apiserver-advertise-address" will be IP address of master node
# sudo kubeadm init
echo $(sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$private_ip) > k8s-worker.log

#extracts the "kubeadm join" command needed to be run on the worker nodes
echo "#extracts the "kubeadm join" command needed to be run on the worker nodes" >> k8s-worker-script.sh
echo $(sed -z 's/.*root: //' k8s-worker.log) >> temp1.txt
echo -n "sudo " >> k8s-worker-script.sh
echo -n $(sed -z 's/\\ --.*/\\/' temp1.txt) >> k8s-worker-script.sh
echo "" >> k8s-worker-script.sh
echo -n "        " >> k8s-worker-script.sh
echo -n $(sed -z 's/.* \\ //' temp1.txt) >> k8s-worker-script.sh

rm temp1.txt

#################################################################################################################
#to start using your cluster, you need to run the following as a regular user:

mkdir -p /.kube
sudo cp -i /etc/kubernetes/admin.conf /.kube/config
sudo chown $(id -u):$(id -g) /.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

#CoreDNS needs a CNI (Container Network Interface) installed for them to get into a “Running” state
#pulling the daemonset weavenet yaml file from s3 (please note weave-daemonset-k8s.yaml has been edited to contain the 10.244.0.0/16 pod-network-cidr)
aws s3 cp s3://pk-bucket-isaac/weave-daemonset-k8s.yaml .

#installing/applying the daemonset weave-net 
kubectl apply -f weave-daemonset-k8s.yaml

#granting the "k8s-worker-script.sh" script executable mode and pushing to s3 bucket
#this will be pulled by the worker node and ran to have the worker node join the pod-network
sudo chmod 777 k8s-worker-script.sh
aws s3 cp k8s-worker-script.sh s3://pk-bucket-isaac

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767398027423.dkr.ecr.us-east-1.amazonaws.com/clixx-repository

#pulling the regcred file from s3. This file 
aws s3 cp s3://pk-bucket-isaac/regcred.sh .
chmod 777 regcred.sh

#running the regcred file with credentials used in deployment yaml file to pull app image from ECR
./regcred.sh

deployment_path=/deployments
services_path=/services

mkdir -p $deployment_path
mkdir -p $services_path

deployment_file=$deployment_path/clixx-deployment.yaml
services_file=$services_path/clixx-app-loadbalancer.yaml

#creating the deployment yaml file for the app deployment
echo "apiVersion: apps/v1" > $deployment_file
echo "kind: Deployment" >> $deployment_file
echo "metadata:" >> $deployment_file
echo "  name: clixx-web-deployment" >> $deployment_file
echo "  labels:" >> $deployment_file
echo "    app: clixx-web-app" >> $deployment_file
echo "spec:" >> $deployment_file
echo "  replicas: 8" >> $deployment_file
echo "  selector:" >> $deployment_file
echo "    matchLabels:" >> $deployment_file
echo "      app: clixx-web-app" >> $deployment_file
echo "  template:" >> $deployment_file
echo "    metadata:" >> $deployment_file
echo "      labels:" >> $deployment_file
echo "        app: clixx-web-app" >> $deployment_file
echo "    spec:" >> $deployment_file
echo "      containers:" >> $deployment_file
echo "      - name: clixx-web-app" >> $deployment_file
echo "        image: 767398027423.dkr.ecr.us-east-1.amazonaws.com/clixx-repository:latest" >> $deployment_file
echo "        imagePullPolicy: Always" >> $deployment_file
echo "        ports:" >> $deployment_file
echo "        - containerPort: 80" >> $deployment_file
echo "      imagePullSecrets:" >> $deployment_file
echo "      - name: regcred" >> $deployment_file

#creating the services yaml file for app services
echo "apiVersion: v1" > $services_file
echo "kind: Service" >> $services_file
echo "metadata:" >> $services_file
echo "  name: clixx-service" >> $services_file
echo "  labels:" >> $services_file
echo "    app: clixx-web-app" >> $services_file
echo "    new_serv: clixx" >> $services_file
echo "spec:" >> $services_file
echo "  type: LoadBalancer" >> $services_file
echo "  selector:" >> $services_file
echo "    app: clixx-web-app" >> $services_file
echo "  ports:" >> $services_file
echo "  - protocol: TCP" >> $services_file
echo "    port: 8080" >> $services_file
echo "    targetPort: 80" >> $services_file
echo "    nodePort: 30000" >> $services_file

#deploying the kubernetes services and deployments for the application
kubectl create -f $services_file
kubectl create -f $deployment_file

#retrieving the load balancer address from terraform output file
load_balancer_dns=${LB_DNS}

#assigning variables for database pulled from AWS Secrets Manager
rds_mysql_endpoint=${rds_mysql_ept}
rds_mysql_user=${rds_mysql_usr}
rds_mysql_password=${rds_mysql_pwd}
rds_mysql_database=${rds_mysql_db}

#updating rds instance / database with the new load balancer dns from terraform output
mysql -h $rds_mysql_endpoint -u $rds_mysql_user -p$rds_mysql_password -D $rds_mysql_database <<EOF
UPDATE wp_options SET option_value = "https://clixx.stack-isaac.com/" WHERE option_id = '1';
UPDATE wp_options SET option_value = "https://clixx.stack-isaac.com/" WHERE option_id = '2';
EOF

# #updating rds instance / database with the new load balancer dns from terraform output
# mysql -h $rds_mysql_endpoint -u $rds_mysql_user -p$rds_mysql_password -D $rds_mysql_database <<EOF
# UPDATE wp_options SET option_value = "$load_balancer_dns" WHERE option_id = '1';
# UPDATE wp_options SET option_value = "$load_balancer_dns" WHERE option_id = '2';
# EOF




