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
  task_role_arn            = "arn:aws:iam::345431723159:role/ecsTaskExecutionRole"
  execution_role_arn       = "arn:aws:iam::345431723159:role/ecsTaskExecutionRole"

  container_definitions = <<DEFINITION
  [
    {
        "name": "jenkins",
        "image": "docker.io/jenkins/jenkins:lts-alpine-jdk11",
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
  name            = "jenkins_ecs_service"
  cluster         = aws_ecs_cluster.jenkins_ecs_cluster.id
  task_definition = aws_ecs_task_definition.jenkins_ecs_td.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  #iam_role        = aws_iam_role.foo.arn
  #depends_on      = [aws_iam_role_policy.foo]
  platform_version        = "LATEST"
  enable_ecs_managed_tags = true

  network_configuration {
    subnets          = ["subnet-088406bf154155db2"]
    security_groups  = [aws_security_group.jenkins_ecs_sg.id]
    assign_public_ip = true
  }
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

