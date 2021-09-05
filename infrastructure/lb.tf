# Application Load Balancer Security Group
resource "aws_security_group" "lb" {
  name    = "${var.project}-${terraform.workspace}-lb"
  vpc_id  = aws_vpc.notejam.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
      ]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
      ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
      ]
  }
}

# Application Load Balancer
resource "aws_lb" "lb" {
  name                = "${var.project}-${terraform.workspace}"
  internal            = false
  load_balancer_type  = "application"
  ip_address_type     = "ipv4"

  security_groups = [
      aws_security_group.lb.id
  ]

  subnets = [
      aws_subnet.lb_a.id,
      aws_subnet.lb_b.id
  ]
}

# Target Group
resource "aws_lb_target_group" "worker" {
  name        = "${var.project}-${terraform.workspace}-worker"
  protocol    = "HTTP"
  port        = var.worker_port[terraform.workspace]
  target_type = "ip"
  vpc_id      = aws_vpc.notejam.id

  deregistration_delay = 30

  health_check {
      protocol = "HTTP"
      path = "/signin/"
  }

  depends_on = [aws_lb.lb]
}

# HTTP Listener
resource "aws_lb_listener" "worker_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.worker.arn
  }
}

output "lb_url" {
  value       = "http://${aws_lb.lb.dns_name}"
}