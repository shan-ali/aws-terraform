provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "jenkins-ecs-cw-log-group" {
  name = "jenkins-cw-log-group"
}

resource "aws_ecs_cluster" "jenkins-ecs-cluster" {
  name = "jenkins-cluster"

  configuration {
    execute_command_configuration {
      # kms_key_id = aws_kms_key.example.arn
      logging    = "OVERRIDE"

      log_configuration {
        # cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.jenkins-ecs-cw-log-group.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "jenkins-ecs-cluster-capacity-provider" {
  cluster_name = aws_ecs_cluster.jenkins-ecs-cluster.name

  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "jenkins-ecs-task-definition" {
  family                   = "jenkins-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  # todo: make tf resource that creates iam role
  task_role_arn            = "arn:aws:iam::345431723159:role/ecsTaskExecutionRole"
  execution_role_arn       = "arn:aws:iam::345431723159:role/ecsTaskExecutionRole"
  container_definitions = <<DEFINITION
  [
    {
      "name": "jenkins",
      "image": "docker.io/jenkins/jenkins:lts-alpine-jdk11",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.jenkins-ecs-cw-log-group.id}",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "jenkins-logs-stream"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "jenkins-ecs-service" {
  name            = "jenkins-service"
  cluster         = aws_ecs_cluster.jenkins-ecs-cluster.id
  task_definition = aws_ecs_task_definition.jenkins-ecs-task-definition.arn
  launch_type = "FARGATE"
  desired_count   = 1
  #iam_role        = aws_iam_role.foo.arn
  #depends_on      = [aws_iam_role_policy.foo]
  platform_version = "LATEST"
  enable_ecs_managed_tags = true

  network_configuration {
    subnets = [ "subnet-088406bf154155db2" ]
    security_groups = [ aws_security_group.jenkins-ecs-sg.id ]
    assign_public_ip = true
  }

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
}

resource "aws_security_group" "jenkins-ecs-sg" {
  name = "jenkins-ecs-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

