# nginx security | nginx-security.tf

# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "${var.nginx_app_name}-load-balancer"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.nginx_app_port
    to_port     = var.nginx_app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.nginx_app_name}-load-balancer"
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.nginx_app_name}-ecs-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.nginx_app_port
    to_port         = var.nginx_app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.nginx_app_name}-ecs-tasks"
  }
}

