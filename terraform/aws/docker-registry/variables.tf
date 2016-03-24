variable "aws_region" {
}

variable "stack_name" {
}

variable "dns_zone_id" {
}
variable "dns_domain_name" {
}

variable "port" {
         default = 5000
}

variable "ami" {
    default = {
        eu-west-1 = "ami-13f84d60"
    }
}

variable "instance_type" {
    default = "t2.small"
}

variable "key_name" {
}

variable "availability_zones" {
}

variable "subnet_ids" {
}

variable "security_group" {
}

variable "min_size" {
    default = "2"
}

variable "max_size" {
    default = "2"
}

variable "desired_capacity" {
    default = "2"
}

variable "health_check_grace_period" {
    default = "300"
}
