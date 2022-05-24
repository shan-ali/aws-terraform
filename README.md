# aws-terraform-jenkins

Deploy Jenkins on an AWS ECS cluster using Terraform and Github Actions

## Table of Contents

## Technologies

- [AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [Jenkins](https://www.jenkins.io/doc/)
- [Docker](https://docs.docker.com/)
- [Terraform](https://www.terraform.io/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

## AWS ECS (Elastic Container Service) Basics

"With [Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html), your containers are defined in a task definition that you use to run an individual task or task within a service. In this context, a service is a configuration that you can use to run and maintain a specified number of tasks simultaneously in a cluster. You can run your tasks and services on a serverless infrastructure that's managed by AWS Fargate."

The main [Amazon ECS components](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/welcome-features.html) are the following:

1. Cluster - a logical grouping of tasks or services
2. Task/Task Definition - describes one or more containers that form your application
3. Service - use an Amazon ECS service to run and maintain your desired number of tasks simultaneously in an Amazon ECS cluster

To simplify this further, we will be creating a task definiton that contains our Jenkins image, a service that sets how many instances of the task to run, a cluster to represent our services and tasks. 

## The Jenkins Image

We will be building a custom Jenkins Docker image named `shanali38/aws-terraform-jenkins` that contains pre installed plugins and one "helloworld" job definition. This is all represented in the [Dockerfile](docker/Dockerfile) in the `docker/` directory. 

The build image will be pushed to a Docker Hub Repository: https://hub.docker.com/repository/docker/shanali38/aws-terraform-jenkins

## Terraform

We will use Terraform to create, update, and delete our AWS infrastructure

### Terraform State

"Terraform must store state about your managed infrastructure and configuration. This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures."

"This state is stored by default in a local file named `terraform.tfstate`, but it can also be stored remotely, which works better in a team environment."

To follow the best practices, we will be using AWS S3 to store our terraform state remotely. The Terraform file [terraform/terraform-backend-s3/main.tf](terraform/terraform-backend-s3/main.tf) contains the resource definitons to create the S3 bucket named `shan-ali-terraform-state` with server side encryption. 

We can run Terraform locally to create this S3 bucket. 

```
cd terraform/terraform-backend-s3
terraform apply 
```

In the Terraform file for creating our AWS Resources for our Jenkins ECS cluster [terraform/jenkins-ecs/main.tf](terraform/jenkins-ecs/main.tf) we specify the S3 backend to use along with the `terraform.tfstate` to store

```
terraform {
  backend "s3" {
    bucket = "shan-ali-terraform-state"
    key    = "ecs/jenkins-ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Resources:
- https://www.terraform.io/language/settings/backends/s3
- https://www.youtube.com/watch?v=FTgvgKT09qM&t=511s&ab_channel=SanjeevThiyagarajan

### Terraform AWS Resources

In the Terraform file for creating our AWS Resources for our Jenkins ECS cluster [terraform/jenkins-ecs/main.tf](terraform/jenkins-ecs/main.tf) we specify the configurations for all the AWS Resources that we need Terraform to create and manage. 

- `jenkins_ecs_cluster`: The AWS ECS Cluster
- `jenkins_ecs_td`: The AWS ECS Task Definition and Container Definition with our Jenkins Image
- `jenkins_ecs_service`: The AWS ECS Service with desired count = 1 and network configurations (subnet, security groups)
- `jenkins_ecs_sg`: The AWS Security group to use for the ECS Service with allows inbound traffic to port 8080 and outbound traffic from port 443 (for dockerhub container image pulling)
- `jenkins_ecs_cw_lg`: The AWS Cloudwatch Logging Group to capture the logs from the Fargate Jenkins container 
 
Resources: 
- https://dev.to/thnery/create-an-aws-ecs-cluster-using-terraform-g80
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service



