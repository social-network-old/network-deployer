# monitoring

# prometheus template
data "template_file" "prometheus_yml" {
  template = file("templates/prometheus.yml")

  vars = {
    workspace             = var.app_name
    monitoring_private_ip = aws_instance.monitoring.private_ip
  }
}

# datasources template
data "template_file" "datasources_yml" {
  template = file("templates/grafana-datasources.yml")

  vars = {
    ip = aws_instance.monitoring.private_ip
  }
}

# alertmanager template
data "template_file" "alertmanager_yml" {
  template = file("templates/alertmanager.yml")

  vars = {
    workspace     = var.app_name
    pagerduty_key = var.prometheus_pagerduty_key
  }
}

# create ebs volume for monitoring instance
resource "aws_ebs_volume" "monitoring" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 10
  type              = "standard"
  snapshot_id       = var.monitoring_snapshot

  lifecycle {
    ignore_changes = [snapshot_id, size]
  }

  tags = {
    Name        = "${var.app_name}-monitoring"
    Environment = var.app_environment
    Role        = "monitoring"
  }
}

# ec2 user data for monitoring
data "template_file" "user_data_monitoring" {
  template = file("templates/monitoring_user_data.sh")

  vars = {
    ecs_cluster = aws_ecs_cluster.main.name
  }
}

# create ec2 instance for monitoring
resource "aws_instance" "monitoring" {
  ami                         = local.aws_ecs_ami
  instance_type               = "t3.medium"
  subnet_id                   = element(aws_subnet.main.*.id, 0)
  depends_on                  = [aws_main_route_table_association.main]
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true
  key_name                    = var.aws_key_pair_name
  iam_instance_profile        = aws_iam_instance_profile.ecsInstanceRole.name
  user_data                   = data.template_file.user_data_monitoring.rendered

  tags = {
    Name        = "${var.app_name}-monitoring"
    Environment = var.app_environment
    Role        = "monitoring"
  }

  volume_tags = {
    Name        = "${var.app_name}-monitoring"
    Environment = var.app_environment
    Role        = "monitoring"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/prometheus",
      "sudo mkdir -p /opt/alertmanager",
      "sudo mkdir -p /opt/grafana/dashboards",
      "sudo mkdir -p /opt/grafana/provisioning/datasources",
      "sudo mkdir -p /opt/grafana/provisioning/dashboards",
      "sudo mkdir -p /opt/grafana/provisioning/notifiers",
      "sudo chown -R ${var.monitoring_username} /opt/prometheus",
      "sudo chown -R ${var.monitoring_username} /opt/alertmanager",
      "sudo chown -R ${var.monitoring_username} /opt/grafana",
    ]

    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }
}

# attach ebs volume to monitoring instance
resource "aws_volume_attachment" "monitoring" {
  instance_id = aws_instance.monitoring.id
  volume_id   = aws_ebs_volume.monitoring.id
  device_name = "/dev/xvdb"

  provisioner "remote-exec" {
    inline = [
      "if ! sudo file -s /dev/nvme1n1 | grep -q filesystem; then sudo mkfs.ext4 /dev/nvme1n1; fi",
      "echo '/dev/nvme1n1 /data ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab",
      "sudo mkdir -p /data; sudo mount /data || true",
      "sudo mkdir -p /data/prometheus && sudo chown 65534 /data/prometheus",
      "sudo mkdir -p /data/alertmanager && sudo chown 65534 /data/alertmanager",
      "sudo mkdir -p /data/grafana && sudo chown 472 /data/grafana",
    ]

    connection {
      host        = aws_instance.monitoring.public_ip
      type        = "ssh"
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }
}

# config prometheus & grafana
resource "null_resource" "monitoring" {
  triggers = {
    monitoring_instance = aws_instance.monitoring.id
    prometheus_config   = sha1(data.template_file.prometheus_yml.rendered)
    grafana_datasources = sha1(data.template_file.datasources_yml.rendered)
  }

  provisioner "file" {
    content     = data.template_file.prometheus_yml.rendered
    destination = "/opt/prometheus/prometheus.yml"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }

  provisioner "file" {
    source      = "templates/prometheus/"
    destination = "/opt/prometheus"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }

  provisioner "file" {
    content     = data.template_file.alertmanager_yml.rendered
    destination = "/opt/alertmanager/alertmanager.yml"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }

  provisioner "file" {
    content     = data.template_file.datasources_yml.rendered
    destination = "/opt/grafana/provisioning/datasources/prometheus.yml"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }

  provisioner "file" {
    content     = file("templates/grafana-dashboards.yml")
    destination = "/opt/grafana/provisioning/dashboards/dashboards.yml"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }

  provisioner "file" {
    source      = "templates/dashboards"
    destination = "/opt/grafana/dashboards/libra"

    connection {
      host        = aws_instance.monitoring.public_ip
      user        = var.monitoring_username
      private_key = file(var.aws_key_pair_file)
    }
  }
}

data "template_file" "ecs_monitoring_definition" {
  template = file("monitoring.json")

  vars = {
    prometheus_image   = "prom/prometheus:v2.9.2"
    alertmanager_image = "prom/alertmanager:v0.17.0"
    grafana_image      = "grafana/grafana:latest"
  }
}

resource "aws_ecs_task_definition" "monitoring" {
  family                = "${var.app_name}-monitoring"
  container_definitions = data.template_file.ecs_monitoring_definition.rendered
  execution_role_arn    = aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name      = "prometheus-data"
    host_path = "/data/prometheus"
  }

  volume {
    name      = "prometheus-config"
    host_path = "/opt/prometheus"
  }

  volume {
    name      = "alertmanager-data"
    host_path = "/data/alertmanager"
  }

  volume {
    name      = "alertmanager-config"
    host_path = "/opt/alertmanager"
  }

  volume {
    name      = "grafana-data"
    host_path = "/data/grafana"
  }

  volume {
    name      = "grafana-provisioning"
    host_path = "/opt/grafana/provisioning"
  }

  volume {
    name      = "grafana-dashboards"
    host_path = "/opt/grafana/dashboards"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "ec2InstanceId == ${aws_instance.monitoring.id}"
  }

  tags = {
    Name        = "${var.app_name}-monitoring"
    Environment = var.app_environment
    Role        = "monitoring"
  }
}

# create ecs service for monitoring
resource "aws_ecs_service" "monitoring" {
  depends_on                         = [null_resource.monitoring, aws_volume_attachment.monitoring]
  name                               = "${var.app_name}-monitoring"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.monitoring.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0

  tags = {
    Name        = "${var.app_name}-monitoring"
    Environment = var.app_environment
    Role        = "monitoring"
  }
}

# output monitoring public ip
output "monitoring_ip" {
  description = "External Ip of monitoring server"
  value       = aws_instance.monitoring.public_ip
}