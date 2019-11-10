# security group and rule for monitoring
resource "aws_security_group" "monitoring" {
  name        = "${var.app_name}-monitoring"
  description = "Monitoring services"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "monitoring-ssh" {
  security_group_id = aws_security_group.monitoring.id
  description       = "admin SSH to monitoring ec2"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_sources_cidr
}

resource "aws_security_group_rule" "monitoring-prometheus" {
  security_group_id = aws_security_group.monitoring.id
  description       = "prometheus monitoring"
  type              = "ingress"
  from_port         = 9090
  to_port           = 9091
  protocol          = "tcp"
  cidr_blocks       = var.admin_sources_cidr
}

resource "aws_security_group_rule" "monitoring-egress" {
  security_group_id = aws_security_group.monitoring.id
  description       = "monitoring-egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "prometheus-query" {
  security_group_id        = aws_security_group.monitoring.id
  description              = "prometheus query"
  type                     = "ingress"
  from_port                = 9091
  to_port                  = 9091
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs-cluster-host.id
}

resource "aws_security_group_rule" "ecs-cluster-svc-mon" {
  security_group_id        = aws_security_group.ecs-cluster-host.id
  description              = "ecs cluster service monitor"
  type                     = "ingress"
  from_port                = 14297
  to_port                  = 14297
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "ecs-cluster-host-mon" {
  security_group_id        = aws_security_group.ecs-cluster-host.id
  description              = "ecs cluster host monitor"
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring.id
}

