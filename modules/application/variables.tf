variable "vpc_id" {}

variable "name" {}

variable "environment" {
  default = "dev"
}

variable "instance_type" {
  type = "map"

  default = {
    dev  = "t2.micro"
    test = "t2.medium"
    prod = "t2.large"
  }
}

variable "extra_sgs" {
  default = []
}

variable "extra_packages" {}

variable "external_nameserver" {}

variable "keypair" {}

variable "instance_count" {
  default = 0
}

variable "subnets" {
  type = "list"
}
