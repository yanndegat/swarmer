output "registry_address" {
  value = "${aws_route53_record.registry.fqdn}"
}
