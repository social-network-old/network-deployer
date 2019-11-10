# Substrate Application Load Balancer - alb.tf

# Define Application Load Balancer
resource "aws_alb" "main" {
  name            = "${var.substrate_app_name}-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
  tags = {
    Name = "${var.substrate_app_name}-alb"
  }
}

# Define ALB Target Group Port 1
resource "aws_alb_target_group" "ecs-alb-tg-1" {
  name        = "${var.substrate_app_name}-alb-tg-1"
  port        = var.substrate_app_port_1
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.app_name}-alb-tg-1"
  }
}

# Redirect all traffic from the ALB to the target group 1
resource "aws_alb_listener" "ecs-alb-listener-1" {
  load_balancer_arn = aws_alb.main.id
  port              = var.substrate_app_port_1
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs-alb-tg-1.id
    type             = "forward"
  }
}

# Define ALB Target Group Port 2
resource "aws_alb_target_group" "ecs-alb-tg-2" {
  name        = "${var.substrate_app_name}-alb-tg-2"
  port        = var.substrate_app_port_2
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.app_name}-alb-tg-2"
  }
}

# Redirect all traffic from the ALB to the target group 2
resource "aws_alb_listener" "ecs-alb-listener-2" {
  load_balancer_arn = aws_alb.main.id
  port              = var.substrate_app_port_2
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs-alb-tg-2.id
    type             = "forward"
  }
}

# Define ALB Target Group Port 3
resource "aws_alb_target_group" "ecs-alb-tg-3" {
  name        = "${var.substrate_app_name}-alb-tg-3"
  port        = var.substrate_app_port_3
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.app_name}-alb-tg-3"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "ecs-alb-listener-3" {
  load_balancer_arn = aws_alb.main.id
  port              = var.substrate_app_port_3
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs-alb-tg-3.id
    type             = "forward"
  }
}

# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "${var.substrate_app_name}-load-balancer"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.substrate_app_port_1
    to_port     = var.substrate_app_port_1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.substrate_app_port_2
    to_port     = var.substrate_app_port_2
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.substrate_app_port_3
    to_port     = var.substrate_app_port_3
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.substrate_app_name}-load-balancer"
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.substrate_app_name}-ecs-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.substrate_app_port_1
    to_port         = var.substrate_app_port_1
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = var.substrate_app_port_2
    to_port         = var.substrate_app_port_2
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = var.substrate_app_port_3
    to_port         = var.substrate_app_port_3
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.substrate_app_name}-ecs-tasks"
  }
}

