# Anagram App / AWS Terraform Infrastructure
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Deploy%20to%20Amazon%20ECS/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Terraform%20Plan/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)
[![Actions Status](https://github.com/draalin/anagram-app-infrastructure/workflows/Terraform%20Deploy/badge.svg)](https://github.com/draalin/anagram-app-infrastructure/actions/)

## Running Locally:
From the root of the directory: `docker-compose up --build`

Open browser to `http://localhost:3000/`
or
From commandline `curl localhost:3000/wordhere`

## Deploying to AWS:

Testing on production:

Update the domain name under `infrastructure/env/production/ terraform.tfvars` to use your domain name that's in Route53.

Open browser to `https://slime.wtf/`
or
From commandline `curl https://slime.wtf/wordhere`