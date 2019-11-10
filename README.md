# Terraform ECS Cluster

Deploy ECS cluster, with monitoring and 4 containers

* **monitoring** --> copy the content of monitoring folder to the root to enable monitoring

* **nginx** --> copy the content of nginx folder to the root to enable deploy ngix with load balancer --> for testing

* **substrate** --> copy the content of substrate folder to the root to enable deploy ngix with load balancer

## Update files

* **terraform.tfvars** --> update AWS credentials and other settings

* **ecs-cluster-variables.tf** --> update ECS cluster settings

* **ecs-cluster-variables.tf** --> update ECS cluster settings

* **variables-substrate.tf** --> update substrate settings / docker image

* **nginx-variables.tf** --> update nginx settings

* **monitoring-variables.tf** --> update monitoring settings

## How to deploy the cluster in AWS

1) Create an IAM user and update the file **terraform.tfvars** with the credentials. To create an IAM user follow the step 1 of the  link below.

https://medium.com/@gmusumeci/how-to-create-an-iam-account-and-configure-terraform-to-use-aws-static-credentials-a8ea4dd4fdfc

2) Update the Amazon ECS ARN and resource ID settings

Open your AWS Console and go to the ECS service. On the left side, under the Amazon ECS, Account Settings, check the Container instance, Service and Task override checkbox.

3) Run Terraform

a) Clone the git repository

b) Update settings and copy folders (if needs), read above

c) Run the command **terraform init** from the command line, in the same folder where your code is located.

d) Then run the command **terraform apply** from the command line to start building the infrastructure.
