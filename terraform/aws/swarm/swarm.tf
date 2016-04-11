resource "aws_instance" "swarm_node_first" {
    ami = "${var.swarm_ami}"
    instance_type = "${var.instance_type}"
    count = "${signum(var.count)}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_group}"]
    subnet_id = "${var.subnet_id}"

    ebs_optimized = "${var.node_ebs_optimized}"

    root_block_device {
       volume_size = "${var.node_datasize}"
    }

    user_data = <<EOF
#cloud-config
coreos:
  update:
    reboot-strategy: off
write_files:
  - path: "/etc/swarm/swarm.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export SWARM_MODE="${var.swarm_mode}"
      export ADMIN_NETWORK="${var.admin_network}"
  - path: "/etc/registrator/registrator.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export ADMIN_NETWORK="${var.admin_network}"
  - path: "/etc/consul/consul.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=${var.consul_joinaddress}
      export CONSUL_MODE="${var.consul_mode}"
      export CLUSTER_SIZE=${var.count}
      export ADMIN_NETWORK="${var.admin_network}"
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node='${var.stack_name}-${var.name}-swarm_manager-0' \
      -dc=${var.vpc_id}"
  - path: "/etc/docker.conf.d/51-additional-docker-opts.conf"
    permissions: "0644"
    owner: "root"
    content: |
             DOCKER_OPTS="${var.additional_docker_opts}"
EOF

    tags  {
        Name = "${var.stack_name}-${var.name}-swarm_manager-0"
        Stack = "${var.stack_name}"
        Type = "swarm_manager"
        Id = "${count.index}"
    }
}

resource "aws_instance" "swarm_node_rest" {
    ami = "${var.swarm_ami}"
    count = "${var.count - signum(var.count)}"
    instance_type = "${var.instance_type}"
    count = 1
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_group}"]
    subnet_id = "${var.subnet_id}"

    ebs_optimized = "${var.node_ebs_optimized}"

    root_block_device {
       volume_size = "${var.node_datasize}"
    }


    user_data = <<EOF
#cloud-config
coreos:
  update:
    reboot-strategy: off
write_files:
  - path: "/etc/swarm/swarm.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export SWARM_MODE="${var.swarm_mode}"
      export ADMIN_NETWORK="${var.admin_network}"
  - path: "/etc/registrator/registrator.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export ADMIN_NETWORK="${var.admin_network}"
  - path: "/etc/consul/consul.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=${aws_instance.swarm_node_first.private_ip}
      export CONSUL_MODE="${var.consul_mode}"
      export CLUSTER_SIZE=${var.count}
      export ADMIN_NETWORK="${var.admin_network}"
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node='${var.stack_name}-${var.name}-swarm_manager-${count.index + 1}' \
      -dc=${var.vpc_id}"
  - path: "/etc/docker.conf.d/51-additional-docker-opts.conf"
    permissions: "0644"
    owner: "root"
    content: |
             DOCKER_OPTS="${var.additional_docker_opts}"
EOF

    tags  {
        Name = "${var.stack_name}-${var.name}-swarm_manager-${count.index + 1}"
        Stack = "${var.stack_name}"
        Type = "swarm_manager"
        Id = "${count.index}"
    }
}
