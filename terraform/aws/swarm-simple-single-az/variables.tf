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

variable "consul_joinaddress" {
    description = "The address of the cluster the consul agent will join."
    default = ""
}

variable "consul_mode" {
    default = "server"
    description = "the Consul agent mode, either agent or server"
}

variable "subnet_id" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "admin_network" {
    description = "The subnet id to bootstrap the swarm instance in."
}

variable "count" {
    default = "3"
    description = "The number of Swarm servers to launch."
}

variable "additional_nodes" {
    default = "0"
    description = "The number of additionnal nodes to launch."
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
variable "bucket" {
    default = ""
    description = "s3 bucket for the registry"
}
