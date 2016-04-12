variable "aws_region" {
    default = "eu-west-1"
}

variable "stack_name" {
}

variable "zone_1" {
    default = "a"
}

variable "zone_2" {
    default = "b"
}

variable "aws_bastion_ami" {
        default = "ami-6b34b418"
}

variable "cidr_prefix" {
    default = {
        eu-west-1 = "10.233"
    }
}

variable "bucket" {
    default = ""
    description = "s3 bucket for the registry"
}
