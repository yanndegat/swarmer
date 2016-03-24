resource "aws_iam_policy" "policy" {
    name = "${var.stack_name}-registry_policy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "${aws_s3_bucket.bucket.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${aws_s3_bucket.bucket.arn}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${var.stack_name}-docker-registry"
    acl = "private"

    tags {
        Name = "${var.stack_name}"
        Environment = "Global"
    }
}

resource "aws_iam_user" "user" {
    name = "${var.stack_name}-registry"
    path = "/${var.stack_name}/system/"
}
resource "aws_iam_access_key" "key" {
    user = "${aws_iam_user.user.name}"
}
resource "aws_iam_policy_attachment" "registry-attach" {
    name = "${var.stack_name}-registry-attachment"
    users = ["${aws_iam_user.user.name}"]
    policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_ecs_task_definition" "registry" {
  family = "${var.stack_name}-registry"
  container_definitions = <<EOF
[
    {
      "name": "registry",
      "image": "allingeek/registry:2-s3",
      "cpu": 1024,
      "memory": 1000,
      "entryPoint": [],
      "environment": [
        {
          "name": "REGISTRY_STORAGE_S3_ACCESSKEY",
          "value": "${aws_iam_access_key.key.id}"
        },
        {
          "name": "REGISTRY_STORAGE_S3_SECRETKEY",
          "value": "${aws_iam_access_key.key.secret}"
        },
        {
          "name": "REGISTRY_STORAGE_S3_REGION",
          "value": "${aws_s3_bucket.bucket.region}"
        },
        {
          "name": "REGISTRY_STORAGE_S3_BUCKET",
          "value": "${aws_s3_bucket.bucket.id}"
        }
      ],
      "command": ["/etc/docker/registry/config.yml"],
      "portMappings": [
        {
          "hostPort": ${var.port},
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "volumesFrom": [],
      "links": [],
      "mountPoints": [],
      "essential": true
    }
]
EOF
}

resource "aws_ecs_cluster" "registry" {
  name = "${var.stack_name}-registry"


   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_ecs_service" "registry" {
  name = "${var.stack_name}-registry"
  cluster = "${aws_ecs_cluster.registry.id}"
  task_definition = "${aws_ecs_task_definition.registry.arn}"
  desired_count = 2
  iam_role = "${aws_iam_role.service.arn}"
  depends_on = ["aws_iam_role_policy.elb"]
  load_balancer {
    elb_name = "${aws_elb.elb.id}"
    container_name = "registry"
    container_port = "${var.port}"
  }

}

resource "aws_iam_role" "service" {
    name = "${var.stack_name}_ecs_service_role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "elb" {
    name = "${var.stack_name}.elb_policy"
    role = "${aws_iam_role.service.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "instance" {
    name = "${var.stack_name}_ecs_instance_role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_iam_instance_profile" "ecs" {
    name = "${var.stack_name}-ecs_instance_profile"
    roles = ["${aws_iam_role.instance.name}"]
#    depends_on = ["aws_iam_role_policy.ecs_instance"]
   lifecycle {
      create_before_destroy = true
    }

}

resource "aws_iam_role_policy" "ecs_instance" {
    name = "${var.stack_name}.ecs_instance_policy"
    role = "${aws_iam_role.instance.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# Create a new load balancer
resource "aws_elb" "elb" {
  name = "${var.stack_name}-registry-elb"
  internal = true
  subnets = ["${split(",", var.subnet_ids)}"]
  security_groups = ["${var.security_group}"]


  listener {
    instance_port = "${var.port}"
    instance_protocol = "http"
    lb_port = "${var.port}"
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:${var.port}/v2/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags  {
        Name = "${var.stack_name}-registry-elb"
        Stack = "${var.stack_name}"
        Type = "registry-elb"
        Id = "0"
  }
}

resource "aws_route53_record" "registry" {
  zone_id = "${var.dns_zone_id}"
  name = "registry.${var.dns_domain_name}"
  type = "A"

  alias {
    name = "${aws_elb.elb.dns_name}"
    zone_id = "${aws_elb.elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_launch_configuration" "ecs" {
    name = "${var.stack_name}"
    image_id = "${lookup(var.ami, var.aws_region)}"
    instance_type = "${var.instance_type}"
    iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
    key_name = "${var.key_name}"
    security_groups = ["${var.security_group}"]
    user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.registry.name} > /etc/ecs/ecs.config
EOF

   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "ecs-cluster" {
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.subnet_ids)}"]
  name = "${var.stack_name}-regsitry"
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  desired_capacity = "${var.desired_capacity}"
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  health_check_grace_period = "${var.health_check_grace_period}"

   lifecycle {
      create_before_destroy = true
    }

  tag {
    key = "Name"
    value = "${var.stack_name}-registry"
    propagate_at_launch = true
  }

 tag {
    key = "Stack"
    value = "${var.stack_name}"
    propagate_at_launch = true
  }

 tag {
    key = "Type"
    value = "registry"
    propagate_at_launch = true
  }

}
