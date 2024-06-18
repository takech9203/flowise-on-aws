# Load Balancer
resource "aws_lb" "public" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  idle_timeout = 30
}

# # Dummy Target Group
# resource "aws_lb_target_group" "dummy" {
#   name        = "${local.name}-dummy-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "ip"

#   health_check {
#     path                = "/"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#     interval            = 6
#     matcher             = "200-299"
#   }
# }

# Listener

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flowise.arn
  }
}

resource "aws_lb_listener_rule" "flowise" {
  listener_arn = aws_lb_listener.public.arn
  priority     = 1
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flowise.arn
  }
}

# Flowise Target Group
resource "aws_lb_target_group" "flowise" {
  name        = "${local.name}-flowise-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 6
    matcher             = "200-299"
  }
}




# Security Group
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Access to the public facing load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.alb_allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}