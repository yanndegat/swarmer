provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_iam_group" "swarmer" {
    name = "${var.stack_name}-swarmer"
    path = "/${var.stack_name}/"
}

resource "aws_iam_user" "swarmer" {
    name = "swarmer"
    path = "/${var.stack_name}/users/"
}

resource "aws_iam_access_key" "swarmer_ak" {
    user = "${aws_iam_user.swarmer.name}"
}

resource "aws_iam_group_policy" "swarmer_policy" {
    name = "swarmer_policy"
    group = "${aws_iam_group.swarmer.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "team_swarmer" {
    name = "tf-testing-group-membership"
    users = [
        "${aws_iam_user.swarmer.name}"
    ]
    group = "${aws_iam_group.swarmer.name}"
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.stack_name}-keypair"
  public_key = "${file("./${var.stack_name}.keypair.pub")}"

   lifecycle {
      create_before_destroy = true
    }
}

#######################
## VPC PROVISIONNING ##
#######################
resource "aws_vpc" "default" {
  cidr_block = "${lookup(var.cidr_prefix, var.aws_region)}.0.0/16"
  enable_dns_hostnames = true
  tags {
     Name = "${var.stack_name}"
  }


   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
     Name = "${var.stack_name}"
  }
}

resource "aws_route53_zone" "zone" {
  name = "${var.stack_name}"
  vpc_id = "${aws_vpc.default.id}"

    tags  {
        Name = "${var.stack_name}-dns-zone"
        Stack = "${var.stack_name}"
        Type = "dns-zone"
        Id = "0"
    }
}

# Public subnets
resource "aws_subnet" "region-public-a" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${lookup(var.cidr_prefix, var.aws_region)}.0.0/24"
    availability_zone = "${var.aws_region}${var.zone_1}"

  tags {
     Name = "${var.stack_name}"
  }
}
resource "aws_subnet" "region-public-b" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${lookup(var.cidr_prefix, var.aws_region)}.2.0/24"
    availability_zone = "${var.aws_region}${var.zone_2}"

  tags {
     Name = "${var.stack_name}"
  }
}

# Routing table for public subnets
resource "aws_route_table" "region-public-a" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
  tags {
     Name = "${var.stack_name}"
  }
}
resource "aws_route_table" "region-public-b" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
  tags {
     Name = "${var.stack_name}"
  }
}

resource "aws_route_table_association" "region-public-a" {
    subnet_id = "${aws_subnet.region-public-a.id}"
    route_table_id = "${aws_route_table.region-public-a.id}"
}

resource "aws_route_table_association" "region-public-b" {
    subnet_id = "${aws_subnet.region-public-b.id}"
    route_table_id = "${aws_route_table.region-public-b.id}"
}

# Private subsets
resource "aws_subnet" "region-private-a" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${lookup(var.cidr_prefix, var.aws_region)}.1.0/24"
    availability_zone = "${var.aws_region}${var.zone_1}"

  tags {
     Name = "${var.stack_name}"
  }

   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_subnet" "region-private-b" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${lookup(var.cidr_prefix, var.aws_region)}.3.0/24"
    availability_zone = "${var.aws_region}${var.zone_2}"
  tags {
     Name = "${var.stack_name}"
  }


   lifecycle {
      create_before_destroy = true
    }
}

# Routing table for private subnets
resource "aws_route_table" "region-private-a" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat_a.id}"
    }
  tags {
     Name = "${var.stack_name}"
  }
}
resource "aws_route_table" "region-private-b" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat_b.id}"
    }
  tags {
     Name = "${var.stack_name}"
  }
}

resource "aws_route_table_association" "region-private-a" {
    subnet_id = "${aws_subnet.region-private-a.id}"
    route_table_id = "${aws_route_table.region-private-a.id}"
}

resource "aws_route_table_association" "region-private-b" {
    subnet_id = "${aws_subnet.region-private-b.id}"
    route_table_id = "${aws_route_table.region-private-b.id}"
}

# Bastion
resource "aws_security_group" "bastion" {
    name = "bastion"
    description = "Allow SSH traffic from the internet"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${lookup(var.cidr_prefix, var.aws_region)}.0.0/16"]
    }

    vpc_id = "${aws_vpc.default.id}"
  tags {
     Name = "${var.stack_name}"
  }


   lifecycle {
      create_before_destroy = true
    }
}

resource "aws_instance" "bastion" {
    ami = "${lookup(var.aws_bastion_ami, var.aws_region)}"
    availability_zone = "${var.aws_region}${var.zone_1}"
    instance_type = "t2.micro"
    key_name = "${var.stack_name}-keypair"
    security_groups = ["${aws_security_group.bastion.id}"]
    subnet_id = "${aws_subnet.region-public-a.id}"

    tags  {
        Name = "${var.stack_name}-bastion-a"
        Stack = "${var.stack_name}"
        Type = "bastion"
        Id = "a"
    }
}

resource "aws_eip" "bastion" {
    instance = "${aws_instance.bastion.id}"
    vpc = true
}
resource "aws_eip" "nat_a" {
    vpc = true
}
resource "aws_eip" "nat_b" {
    vpc = true
}

resource "aws_nat_gateway" "nat_a" {
    allocation_id = "${aws_eip.nat_a.id}"
    subnet_id = "${aws_subnet.region-public-a.id}"
}

resource "aws_nat_gateway" "nat_b" {
    allocation_id = "${aws_eip.nat_b.id}"
    subnet_id = "${aws_subnet.region-public-b.id}"
}


#Nodes
resource "aws_security_group" "nodes" {
    name = "nodes"
    description = "Allow SSH traffic from the Bastion"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
    }

    #consul tcp
    ingress {
        from_port = 8300
        to_port = 8300
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 8301
        to_port = 8301
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 8302
        to_port = 8302
        protocol = "tcp"
        self = true
    }
    #consul udp
    ingress {
        from_port = 8300
        to_port = 8300
        protocol = "udp"
        self = true
    }
    ingress {
        from_port = 8301
        to_port = 8301
        protocol = "udp"
        self = true
    }
    ingress {
        from_port = 8302
        to_port = 8302
        protocol = "udp"
        self = true
    }
    #docker
    ingress {
        from_port = 2375
        to_port = 2376
        protocol = "tcp"
        self = true
    }
    #docker swarm
    ingress {
        from_port = 4000
        to_port = 4000
        protocol = "tcp"
        self = true
    }
    #docker registry
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        self = true
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"
    tags {
       Name = "${var.stack_name}"
    }


   lifecycle {
      create_before_destroy = true
   }
}
resource "aws_route53_record" "bastion_dns_records" {
    zone_id = "${aws_route53_zone.zone.zone_id}"
    name = "bastion.${var.stack_name}"
    type = "A"
    ttl = "30"
    records = ["${aws_instance.bastion.private_ip}"]
   lifecycle {
      create_before_destroy = true
   }
   depends_on = ["aws_security_group.nodes"]
}
