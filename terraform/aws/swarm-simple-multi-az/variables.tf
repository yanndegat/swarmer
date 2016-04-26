variable "aws_region" {
    default = "eu-west-1"
}

variable "swarmer_ami" {
    description = "AWS AMI Id, if you change, make sure it is compatible with instance type, not all AMIs allow all instance types "
}

variable "vpc_id" {
    description = "The Id of the VPC to boostrap the swarm cluster in."
}

variable "name" {
    description = "The Name of the swarm cluster."
    default = "DC1"
}

variable "additional_docker_opts" {
    description = "Additional docker engine options."
    default = ""
}

variable "security_group" {
    description = "The Id of the security group to deploy the cluster in."
}

variable "key_name" {
    description = "SSH key name in your AWS account for AWS instances."
}

variable "swarm_mode" {
    default = "both"
    description = "the swarm mode, either agent, manager or both"
}

variable "subnet_id_zone_a" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "subnet_id_zone_b" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "subnet_network_zone_a" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "subnet_network_zone_b" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "count" {
    default = "3"
}

variable "additional_nodes_zone_a" {
    default = "0"
    description = "The number of additionnal nodes to launch in zone b."
}

variable "additional_nodes_zone_b" {
    default = "0"
    description = "The number of additionnal nodes to launch in zone b."
}

variable "instance_type" {
    default = "m4.large"
    description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}

variable "node_datasize" {
    default = "100"
    description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}
variable "node_ebs_optimized"{
    default = "true"
}

variable "stack_name" {
    default = "swarm"
    description = "Name tag for the servers"
}

variable "registry_access_key_id" {
    default = ""
    description = "aws access key for the registry"
}

variable "registry_access_key_secret" {
    default = ""
    description = "aws access key for the registry"
}

variable "rexray_access_key_id" {
    default = ""
    description = "aws access key for rexray"
}

variable "rexray_access_key_secret" {
    default = ""
    description = "aws access key for rexray"
}

variable "bucket" {
    default = ""
    description = "s3 bucket for the registry"
}
