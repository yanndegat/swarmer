output "registry_access_key_id" {
  value = "${aws_iam_access_key.registry.id}"
}
output "registry_access_key_secret" {
  value = "${aws_iam_access_key.registry.secret}"
}
output "rexray_access_key_id" {
  value = "${aws_iam_access_key.rexray_ak.id}"
}
output "rexray_access_key_secret" {
  value = "${aws_iam_access_key.rexray_ak.secret}"
}
output "swarmer_access_key_id" {
  value = "${aws_iam_access_key.swarmer_ak.id}"
}
output "swarmer_access_key_secret" {
  value = "${aws_iam_access_key.swarmer_ak.secret}"
}
output "key_name" {
  value = "${aws_key_pair.keypair.key_name}"
}
output "subnet_id_zone_a" {
  value = "${aws_subnet.region-private-a.id}"
}
output "subnet_network_zone_a" {
  value = "${aws_subnet.region-private-a.cidr_block}"
}
output "subnet_id_zone_b" {
  value = "${aws_subnet.region-private-b.id}"
}
output "subnet_network_zone_b" {
  value = "${aws_subnet.region-private-b.cidr_block}"
}
output "security_group" {
  value = "${aws_security_group.nodes.id}"
}
output "vpc_id" {
  value = "${aws_vpc.default.id}"
}
output "bastion_ip" {
  value = "${aws_eip.bastion.public_ip}"
}
output "dns_zone_id" {
  value = "${aws_route53_zone.zone.zone_id}"
}
output "dns_domain_name" {
  value = "${aws_route53_zone.zone.name}"
}
output "availability_zones"{
  value = "${var.aws_region}a,${var.aws_region}b"
}
output "subnet_ids"{
  value = "${aws_subnet.region-private-a.id},${aws_subnet.region-private-b.id}"
}
