output "join_address" {
    value = "${aws_instance.swarm_node_first.private_ip}"
}
