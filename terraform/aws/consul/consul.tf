resource "aws_instance" "consul_server_leader" {
    ami = "${var.consul_ami}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_group}"]
    subnet_id = "${var.subnet_id}"
    user_data = <<EOT
#cloud-config
coreos:
  update:
    reboot-strategy: off
write_files:
  - path: "/etc/consul/consul.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=${var.joinaddress}
      export CLUSTER_SIZE=${var.servers}
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node='${var.stack_name}-${var.name}-consul_server-0' \
      -dc=${var.vpc_id}"
  - path: "/etc/systemd/system/docker.service.d/51-additional-docker-opts.conf"
    permissions: "0644"
    owner: "root"
    content: |
             Environment='DOCKER_OPTS=${var.additional_docker_opts}'
EOT

    tags  {
        Name = "${var.stack_name}-${var.name}-consul_server-0"
        Stack = "${var.stack_name}"
        Type = "consul_server"
        Id = "0"
    }
}

resource "aws_instance" "consul_server_peers" {
    ami = "${var.consul_ami}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    count = "${var.servers - 1}"
    vpc_security_group_ids = ["${var.security_group}"]
    subnet_id = "${var.subnet_id}"
    user_data = <<EOT
#cloud-config
coreos:
  update:
    reboot-strategy: off
write_files:
  - path: "/etc/consul/consul.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export JOINIPADDR=${coalesce(var.joinaddress,aws_instance.consul_server_leader.private_ip)}
      export CLUSTER_SIZE=${var.servers}
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node='${var.stack_name}-${var.name}-consul_server-${count.index + 1}' \
      -dc=${var.vpc_id}"
  - path: "/etc/systemd/system/docker.service.d/51-additional-docker-opts.conf"
    permissions: "0644"
    owner: "root"
    content: |
             Environment='DOCKER_OPTS=$DOCKER_OPTS ${var.additional_docker_opts}'
EOT

    tags  {
        Name = "${var.stack_name}-${var.name}-consul_server-${count.index + 1}"
        Stack = "${var.stack_name}"
        Type = "consul_server"
        Id = "${count.index + 1}"
    }
}
