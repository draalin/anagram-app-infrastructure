# Anagram App / AWS Terraform Infrastructure
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Deploy%20to%20Amazon%20ECS/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Terraform%20Plan/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Terraform%20Deploy/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)

This is a Node.js Anagram app that has been built out with Terraform onto AWS and deployed by Github Actions.

![Infrastructure](infrastructure.svg)

## Getting started
The deployment of this web application and infrasturcture is split into two steps.

The infrastructure itself and the initialization steps of said infrastructure.
Specific resources need to be created for the infrastructure which we'll provision first.

### Initizliation
```
cd infrastructure/env
terraform init
terraform apply --auto-approve
```

Copy output of `aws access` and `secret key`

### Infrastructure Deployment
Remember to update the `terraform.tfvars` for your requirements.

The deployment can be done through Github Actions with any change made under `infrastructure/**` or locally (see below).

If doing this through Github Actions you'll have to create secrets for:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

#### Locally
```
cd infrastructure/env/production
```
Update the `.env` with the copied aws access and secret keys in the prior step.

To keep things simple I built out a single environment, we'll call it the `production` environment.

This can easily be duplicated by taking advantage of Terraform `workspaces`.
```
source .env
terraform init
terraform workspace new production
terraform workspace select production
terraform apply --auto-approve
```

## Accessing Container Resources
### Bastion
All access is done through a Bastion host. You will need the `slime.pem` file, then run:
`ssh -i slime.pem ec2-user@bastion.slime.wtf`

### ECS Container Instance
Once connected to the Bastion host you can SSH into the ECS Instance
`ssh core@xxx.xxx.xxx.xxx.ec2.internal`

### Accessing ECS Containers
To access a Docker container, run the following command
```docker exec -it $(docker ps | grep 'slime-web' | awk '{print $1}') /bin/bash```

## Running Anagram App Locally:
From the root of the directory: `docker-compose up --build`

Open browser to `http://localhost:3000/`

or

From commandline `curl localhost:3000/wordhere`

## Accessing the production Applciation
Remember: Update the domain name under `infrastructure/env/production/ terraform.tfvars` to use a domain you have within Route53.

Open browser to `https://slime.wtf/`

or

From commandline `curl https://slime.wtf/wordhere`

## Resource Graph
![Infrastructure Terraform](https://raw.githubusercontent.com/draalin/anagram-app-infrastructure/master/infrastructure-terraform.svg?sanitize=true)