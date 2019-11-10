# Deploying Substrate Container | substrate-container.tf

# container template
data "template_file" "substrate_app" {
  template = file("./substrate.json")

  vars = {
    app_name       = var.substrate_app_name
    app_image      = var.substrate_app_image
    app_port_1     = var.substrate_app_port_1
    app_port_2     = var.substrate_app_port_2
    app_port_3     = var.substrate_app_port_3
    fargate_cpu    = var.substrate_fargate_cpu
    fargate_memory = var.substrate_fargate_memory
    aws_region     = var.aws_region
  }
}

# ECS task definition
resource "aws_ecs_task_definition" "substrate_app" {
  family                   = "substrate-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.substrate_fargate_cpu
  memory                   = var.substrate_fargate_memory
  container_definitions    = data.template_file.substrate_app.rendered
}

# ECS service
resource "aws_ecs_service" "substrate_app" {
  name            = var.substrate_app_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.substrate_app.arn
  desired_count   = var.substrate_app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  depends_on = [aws_alb_listener.ecs-alb-listener-1, aws_alb_listener.ecs-alb-listener-2, aws_alb_listener.ecs-alb-listener-3, aws_iam_role_policy_attachment.ecs_task_execution_role]

   tags = {
    Name = "${var.substrate_app_name}-ecs"
  }
}

 