# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
}

# Flowise ECS Service
resource "aws_ecs_service" "flowise" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flowise.arn
  desired_count   = 2         # Number of tasks to run in the ECS service
  launch_type     = "FARGATE" # Using AWS Fargate for running containers

  network_configuration {
    subnets          = module.vpc.private_subnets        # Private subnets for the tasks
    security_groups  = [aws_security_group.container.id] # Security group for the tasks
    assign_public_ip = false                             # Tasks will not have public IP addresses
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flowise.arn # Target group for the load balancer
    container_name   = "flowise-service"               # Container name in the task definition
    container_port   = 3000                            # Container port to forward traffic to
  }

  depends_on = [
    aws_lb_listener_rule.flowise,
  ]
}

# CWL

resource "aws_cloudwatch_log_group" "flowise" {
  name              = "${local.name}-flowise-logs"
  retention_in_days = 7 # Adjust the log retention period as needed
}


# ECS Task Definition
resource "aws_ecs_task_definition" "flowise" {
  family                   = "${local.name}-flowise-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "flowise-service"
      image     = "flowiseai/flowise:${local.flowise.version}"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "Port"
          value = "3000"
        },
        {
          name  = "CORS_ORIGINS"
          value = ""
        },
        {
          name  = "IFRAME_ORIGINS"
          value = ""
        },
        {
          name  = "FLOWISE_USERNAME"
          value = ""
        },
        {
          name  = "FLOWISE_PASSWORD"
          value = ""
        },
        {
          name  = "FLOWISE_FILE_SIZE_LIMIT"
          value = ""
        },
        {
          name  = "DEBUG"
          value = ""
        },
        {
          name  = "DATABASE_PATH"
          value = "/root/.flowise"
        },
        {
          name  = "DATABASE_TYPE"
          value = ""
        },
        {
          name  = "DATABASE_PORT"
          value = ""
        },
        {
          name  = "DATABASE_HOST"
          value = ""
        },
        {
          name  = "DATABASE_NAME"
          value = ""
        },
        {
          name  = "DATABASE_USER"
          value = ""
        },
        {
          name  = "DATABASE_PASSWORD"
          value = ""
        },
        {
          name  = "DATABASE_SSL"
          value = ""
        },
        {
          name  = "DATABASE_SSL_KEY_BASE64"
          value = ""
        },
        {
          name  = "APIKEY_PATH"
          value = "/root/.flowise"
        },
        {
          name  = "SECRETKEY_PATH"
          value = "/root/.flowise"
        },
        {
          name  = "FLOWISE_SECRETKEY_OVERWRITE"
          value = ""
        },
        {
          name  = "LOG_LEVEL"
          value = ""
        },
        {
          name  = "LOG_PATH"
          value = "/root/.flowise/logs"
        },
        {
          name  = "BLOB_STORAGE_PATH"
          value = "/root/.flowise/storage"
        },
        {
          name  = "DISABLE_FLOWISE_TELEMETRY"
          value = ""
        }
      ]
      command = [
        "/bin/sh",
        "-c",
        "sleep 3; flowise start"
      ]
      mountPoints = [
        {
          sourceVolume  = "efs-volume"
          containerPath = "/root/.flowise"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.flowise.id
          awslogs-region        = local.region
          awslogs-stream-prefix = local.name
        }
      }
    }
  ])

  volume {
    name = "efs-volume"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
}




resource "aws_security_group" "container" {
  name        = "${local.name}-container-sg"
  description = "Access to the containers"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# IAM

# IAM Roles
resource "aws_iam_role" "auto_scaling" {
  name               = "${local.name}-as-role"
  assume_role_policy = data.aws_iam_policy_document.auto_scaling_role_assume_policy.json
}

data "aws_iam_policy_document" "auto_scaling_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "auto_scaling_role_policy_attachment" {
  role       = aws_iam_role.auto_scaling.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_iam_role" "ecs_service" {
  name               = "${local.name}-ecs-svc-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role_assume_policy.json
}

data "aws_iam_policy_document" "ecs_service_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs-service"
  role   = aws_iam_role.ecs_service.id
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_policy_attachment" {
  role       = aws_iam_role.ecs_service.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_policy.json
}

data "aws_iam_policy_document" "ecs_task_execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name   = "AmazonECSTaskExecutionRolePolicy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.ecs_task_execution_role_policy.json
}

data "aws_iam_policy_document" "ecs_task_execution_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeFileSystems",
    ]
    resources = [aws_efs_file_system.main.arn]
  }
}
