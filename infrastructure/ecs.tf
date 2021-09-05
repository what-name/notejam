variable "worker_images_to_keep" { type = map(string) }
variable "worker_port" { type = map(string) }
variable "worker_deployment_min_healthy" { type = map(string) }
variable "worker_deployment_max_healthy" { type = map(string) }
variable "worker_cpu" { type = map(string) }
variable "worker_memory" { type = map(string) }
variable "worker_assign_public_ip" { type = map(string) }
variable "worker_health_check_grace_period" { type = map(string) }


# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-${terraform.workspace}"
}

# ECR
resource "aws_ecr_repository" "ecr" {
  name = "${var.project}-${terraform.workspace}"
}
# ECR Policy
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr.name
  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.worker_images_to_keep[terraform.workspace]} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.worker_images_to_keep[terraform.workspace]}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# Standard IAM Policy for ECS task
data "aws_iam_policy" "ecs-task-execution-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task execution role
resource "aws_iam_role" "task_execution" {
  name = "${var.project}-${terraform.workspace}-task-execution"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role = aws_iam_role.task_execution.name
  policy_arn = data.aws_iam_policy.ecs-task-execution-policy.arn
}

# Security Group for ECS service allowing the traffic only from LB
resource "aws_security_group" "worker" {
  name   = "${var.project}-${terraform.workspace}-worker"
  vpc_id = aws_vpc.notejam.id

  ingress {
    from_port       = var.worker_port[terraform.workspace]
    to_port         = var.worker_port[terraform.workspace]
    protocol        = "tcp"
    security_groups = [
      aws_security_group.lb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group for ECS console logs
resource "aws_cloudwatch_log_group" "worker_console" {
  name = "/ecs/${var.project}-${terraform.workspace}-worker-console"
}

# ECS Task Definition
data "template_file" "ecs_container_definitions" {
  template = file("./ecs_container_definition.json")

  vars = {
    image            = "${local.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project}-${terraform.workspace}:latest"
    log_group        = aws_cloudwatch_log_group.worker_console.name
    region           = var.region,
    db_host          = aws_rds_cluster.notejam.endpoint
    db_port          = aws_rds_cluster.notejam.port
    db_name          = aws_rds_cluster.notejam.database_name
    db_username      = aws_rds_cluster.notejam.master_username
    db_password      = aws_rds_cluster.notejam.master_password
    container_port   = var.worker_port[terraform.workspace]
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                    = "${var.project}-${terraform.workspace}-worker"
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  execution_role_arn        = aws_iam_role.task_execution.arn

  cpu    = var.worker_cpu[terraform.workspace]
  memory = var.worker_memory[terraform.workspace]

  container_definitions = data.template_file.ecs_container_definitions.rendered
}

#ECS Service
resource "aws_ecs_service" "worker" {
  name              = "${var.project}-${terraform.workspace}-worker"
  launch_type       = "FARGATE"
  task_definition   = aws_ecs_task_definition.worker.arn
  cluster           = aws_ecs_cluster.cluster.arn

  # The initial desired count to start with before Service Auto Scaling begins adjustment.
  desired_count     = 1

  deployment_minimum_healthy_percent = var.worker_deployment_min_healthy[terraform.workspace]
  deployment_maximum_percent         = var.worker_deployment_max_healthy[terraform.workspace]
  health_check_grace_period_seconds  = var.worker_health_check_grace_period[terraform.workspace]


  network_configuration {
      subnets = [
        aws_subnet.ecs_a.id,
        aws_subnet.ecs_b.id
      ]
      security_groups = [
        aws_security_group.worker.id
      ]
      assign_public_ip = var.worker_assign_public_ip[terraform.workspace]
  }

  load_balancer {
      target_group_arn  = aws_lb_target_group.worker.arn
      container_name    = "worker"
      container_port    = var.worker_port[terraform.workspace]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  depends_on = [aws_ecs_cluster.cluster]
}
