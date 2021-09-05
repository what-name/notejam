variable "autoscaling_min_count" { type = map(string) }
variable "autoscaling_max_count" { type = map(string) }
variable "autoscaling_alarm_statistic" { type = map(string) }
variable "autoscaling_up_cooldown" { type = map(string) }
variable "autoscaling_up_adjustment" { type = map(string) }
variable "autoscaling_down_cooldown" { type = map(string) }
variable "autoscaling_down_adjustment" { type = map(string) }
variable "autoscaling_cpu_low_threshold" { type = map(string) }
variable "autoscaling_cpu_low_period" { type = map(string) }
variable "autoscaling_cpu_low_period_counts" { type = map(string) }
variable "autoscaling_cpu_high_period_counts" { type = map(string) }
variable "autoscaling_cpu_high_period" { type = map(string) }
variable "autoscaling_cpu_high_threshold" { type = map(string) }

data "aws_iam_role" "ecs_auto_scale" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

# ECS Autoscaling
resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"
  max_capacity       = var.autoscaling_max_count[terraform.workspace]
  min_capacity       = var.autoscaling_min_count[terraform.workspace]
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = data.aws_iam_role.ecs_auto_scale.arn
}

# Auto scaling policy(down)
resource "aws_appautoscaling_policy" "down" {
  name               = "${var.project}-${terraform.workspace}-worker-scale-down"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"

  step_scaling_policy_configuration {
    metric_aggregation_type = "Maximum"
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.autoscaling_down_cooldown[terraform.workspace]

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.autoscaling_down_adjustment[terraform.workspace]
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

# Auto scaling policy(up)
resource "aws_appautoscaling_policy" "up" {
  name               = "${var.project}-${terraform.workspace}-worker-scale-up"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"

  step_scaling_policy_configuration {
    metric_aggregation_type = "Maximum"
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.autoscaling_up_cooldown[terraform.workspace]

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.autoscaling_up_adjustment[terraform.workspace]
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

# CloudWatch alarm to scale down
resource "aws_cloudwatch_metric_alarm" "worker_cpu_low" {
  alarm_name          = "${var.project}-${terraform.workspace}-worker-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = var.autoscaling_alarm_statistic[terraform.workspace]
  threshold           = var.autoscaling_cpu_low_threshold[terraform.workspace]
  period              = var.autoscaling_cpu_low_period[terraform.workspace]
  evaluation_periods  = var.autoscaling_cpu_low_period_counts[terraform.workspace]

  dimensions = {
    ServiceName = aws_ecs_service.worker.name
    ClusterName = aws_ecs_cluster.cluster.name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]
}

# CloudWatch alarm to scale up
resource "aws_cloudwatch_metric_alarm" "worker_cpu_high" {
  alarm_name          = "${var.project}-${terraform.workspace}-worker-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = var.autoscaling_alarm_statistic[terraform.workspace]
  threshold           = var.autoscaling_cpu_high_threshold[terraform.workspace]
  period              = var.autoscaling_cpu_high_period[terraform.workspace]
  evaluation_periods  = var.autoscaling_cpu_high_period_counts[terraform.workspace]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.worker.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}
