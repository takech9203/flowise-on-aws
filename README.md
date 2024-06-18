# flowise-on-aws <!-- omit in toc -->

- [Overview](#overview)
- [Instructions](#instructions)
  - [Install prerequisite software](#install-prerequisite-software)
    - [Log in to an AWS account](#log-in-to-an-aws-account)
    - [Set AWS credentials](#set-aws-credentials)
    - [Clone Git repository](#clone-git-repository)
  - [Configure and deploy the environment (Terraform)](#configure-and-deploy-the-environment-terraform)
    - [Configure the environment](#configure-the-environment)
    - [Deploy the environment](#deploy-the-environment)
    - [Open application](#open-application)
    - [Clean up](#clean-up)
  - [Configure and deploy the environment (CloudFormation)](#configure-and-deploy-the-environment-cloudformation)
    - [Deploy the environment](#deploy-the-environment-1)
    - [Open application](#open-application-1)
    - [Clean up](#clean-up-1)
- [Security](#security)
- [License](#license)



## Overview

Deploy AWS infrastructure for [Flowise](https://github.com/FlowiseAI/Flowise).


## Instructions


### Install prerequisite software

Follow the instruction below to install each software.

* AWS CLI version 2: [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Terraform: [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)



#### Log in to an AWS account

Launch a web browser and log in to the AWS Management Console as a user with administrative privileges.


#### Set AWS credentials

Launch a terminal and set the AWS credentials as environment variables on the terminal.

For example:

```shell
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

#### Clone Git repository

Run the command below to clone the git repository.

```
git clone https://gitlab.aws.dev/kunimasa/flowise-on-aws
```

### Configure and deploy the environment (Terraform)

#### Configure the environment

Copy `terraform/terraform.tfvars.template` file to `terraform/terraform.tfvars`.

```shell
cd terraform
cp terraform/terraform.tfvars.template terraform/terraform.tfvars
```

Update ubuntu default password information in `terraform/terraform.tfvars`.

```shell
alb_allowed_ip = "1.1.1.1/32"
```

Configure `terraform/main.tf` when needed.

* Replace AWS region code you use

```hcl
locals {
  name       = "flowise-on-aws-tf" # Project name
  region     = "ap-northeast-1"    # Specify your AWS region
  account_id = data.aws_caller_identity.current.account_id
  vpc = {
    cidr = "10.1.0.0/16" # VPC IPv4 CIDR
  }

  flowise = {
    version = "1.8.1"
  }
```

#### Deploy the environment

Run the following commands to deploy the infrastructure. Make sure to run the command in `terraform/` directory.

```shell
cd terraform/
terraform init
terraform plan
terraform apply --auto-approve
```

#### Open application

```
open $(terraform output -raw external_url)
```


#### Clean up

```shell
cd terraform/
terraform init
terraform plan
terraform apply --auto-approve
```


### Configure and deploy the environment (CloudFormation)

Cusomized CFn template in [AWS | FlowiseAI](https://docs.flowiseai.com/configuration/deployment/aws).


#### Deploy the environment

Run the following commands to deploy the infrastructure. Make sure to run the command in `cloudformation/` directory.


```shell
cd cloudformation/

REGION="ap-northeast-1"
ALLOWED_IP="1.1.1.1/32"

aws cloudformation --region ${REGION} create-stack --stack-name flowise --template-body file://flowise-cloudformation.yml --capabilities CAPABILITY_IAM --parameters ParameterKey=AlbAllowedIp,ParameterValue=${ALLOWED_IP}
```

```shell
aws cloudformation --region ${REGION} describe-stacks --stack-name flowise --query 'Stacks[*].Outputs[*].OutputValue' --output text
```

#### Open application

```
open $(aws cloudformation --region ${REGION} describe-stacks --stack-name flowise --query 'Stacks[*].Outputs[*].OutputValue' --output text)
```

#### Clean up

```shell
REGION="ap-northeast-1"
aws cloudformation --region ${REGION} delete-stack --stack-name flowise 
```


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.


## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.

