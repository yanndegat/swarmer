output "join_address" {
    value = "${aws_instance.consul_server_leader.private_ip}"
}
