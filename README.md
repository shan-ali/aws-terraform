# aws-terraform-jenkins

Deploy Jenkins on an AWS ECS cluster using Terraform and Github Actions

## Table of Contents

## Technologies

- [AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [Terraform](https://www.terraform.io/docs)
- [Docker](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Jenkins](https://www.jenkins.io/doc/)

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
