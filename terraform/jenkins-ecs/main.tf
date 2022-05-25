terraform {
  backend "s3" {
    bucket = "shan-ali-terraform-state"
    key    = "ecs/jenkins-ecs/terraform.tfstate"
    region = "us-east-1"
  }
}

variable "docker_image" {
  type        = string
  description = "The docker image to deploy."
  default     = "shanali38/aws-terraform-jenkins:latest"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "jenkins_ecs_cw_lg" {
  name = "/ecs/jenkins_ecs_cw_lg"
}

resource "aws_ecs_cluster" "jenkins_ecs_cluster" {
  name = "jenkins_ecs_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "jenkins_ecs_cluster_capacity_provider" {
  cluster_name       = aws_ecs_cluster.jenkins_ecs_cluster.name
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "jenkins_ecs_td" {
  family                   = "jenkins_ecs_td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<DEFINITION
  [
    {
        "name": "jenkins",
        "image": "${var.docker_image}",
        "cpu": 0,
        "links": [],
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {              
                "awslogs-group": "${aws_cloudwatch_log_group.jenkins_ecs_cw_lg.name}",
                "awslogs-region": "us-east-1",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
  ]
  DEFINITION 

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "jenkins_ecs_service" {
  name                               = "jenkins_ecs_service"
  cluster                            = aws_ecs_cluster.jenkins_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.jenkins_ecs_td.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  platform_version                   = "LATEST"
  enable_ecs_managed_tags            = true

  network_configuration {
    subnets          = ["subnet-088406bf154155db2"]
    security_groups  = [aws_security_group.jenkins_ecs_sg.id]
    assign_public_ip = true
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "jenkins_ecs_execution_task_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "jenkins_ecs_iam_role"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_security_group" "jenkins_ecs_sg" {
  name = "jenkins_ecs_sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


