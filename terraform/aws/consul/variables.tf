variable "consul_ami" {
    description = "AWS AMI Id, if you change, make sure it is compatible with instance type, not all AMIs allow all instance types "
}

variable "vpc_id" {
    description = "The Id of the VPC to boostrap the consul cluster in."
}

variable "name" {
    description = "The Name of the consul cluster."
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

variable "joinaddress" {
    description = "The subnet id to bootstrap the consul instance in."
    default = ""
}

variable "subnet_id" {
    description = "The subnet id to bootstrap the consul instance in."
}

variable "servers" {
    default = "5"
    description = "The number of Consul servers to launch."
}

variable "instance_type" {
    default = "t2.micro"
    description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}

variable "stack_name" {
    default = "consul"
    description = "Name tag for the servers"
}
