resource "aws_instance" "swarm_node_first" {
    ami = "${var.swarmer_ami}"
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
  - path: "/etc/rexray/config.yml"
    permissions: "0644"
    owner: "root"
    content: |
      rexray:
        storageDrivers:
          - ec2
      aws:
        accessKey: ${var.rexray_access_key_id}
        secretKey: ${var.rexray_access_key_secret}
        rexrayTag: ${var.stack_name}
  - path: "/etc/swarmer/swarmer.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export SWARM_MODE="${var.swarm_mode}"
      export ADMIN_NETWORK="${var.admin_network}"
      export JOINIPADDR=${var.consul_joinaddress}
      export CONSUL_MODE="${var.consul_mode}"
      export CLUSTER_SIZE=${var.count}
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node=${var.stack_name}-${var.name}-swarm_manager-0 \
      -dc=${var.vpc_id}"
  - path: "/etc/docker/registry/config.yml"
    permissions: "0644"
    owner: "root"
    content: |
      version: 0.1
      log:
        fields:
          service: registry
      storage:
        s3:
          accesskey: ${var.registry_access_key_id}
          secretkey: ${var.registry_access_key_secret}
          region: ${var.aws_region}
          bucket: ${var.bucket}
          encrypt: true
          secure: true
          v4auth: true
          chunksize: 5242880
          rootdirectory: /docker-registry
        cache:
          blobdescriptor: inmemory
      http:
        addr: :5000
        headers:
          X-Content-Type-Options: [nosniff]
      health:
        storagedriver:
          enabled: true
          interval: 10s
          threshold: 3
  - path: "/etc/swarmer/docker.conf.d/51-additional-docker-opts.conf"
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
    ami = "${var.swarmer_ami}"
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
  - path: "/etc/rexray/config.yml"
    permissions: "0644"
    owner: "root"
    content: |
      rexray:
        storageDrivers:
          - ec2
      aws:
        accessKey: ${var.rexray_access_key_id}
        secretKey: ${var.rexray_access_key_secret}
        rexrayTag: ${var.stack_name}
  - path: "/etc/swarmer/swarmer.conf"
    permissions: "0644"
    owner: "root"
    content: |
      export SWARM_MODE="${var.swarm_mode}"
      export ADMIN_NETWORK="${var.admin_network}"
      export JOINIPADDR=${aws_instance.swarm_node_first.private_ip}
      export CONSUL_MODE="${var.consul_mode}"
      export CLUSTER_SIZE=${var.count}
      export CONSUL_OPTS="$CONSUL_OPTS \
      -node=${var.stack_name}-${var.name}-swarm_manager-${count.index + 1} \
      -dc=${var.vpc_id}"
  - path: "/etc/docker/registry/config.yml"
    permissions: "0644"
    owner: "root"
    content: |
      version: 0.1
      log:
        fields:
          service: registry
      storage:
        s3:
          accesskey: ${var.registry_access_key_id}
          secretkey: ${var.registry_access_key_secret}
          region: ${var.aws_region}
          bucket: ${var.bucket}
          encrypt: true
          secure: true
          v4auth: true
          chunksize: 5242880
          rootdirectory: /docker-registry
        cache:
          blobdescriptor: inmemory
      http:
        addr: :5000
        headers:
          X-Content-Type-Options: [nosniff]
      health:
        storagedriver:
          enabled: true
          interval: 10s
          threshold: 3
  - path: "/etc/swarmer/docker.conf.d/51-additional-docker-opts.conf"
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
