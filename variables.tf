variable "region" {
  description = "Aws region. Changing it will lead to loss of complete stack.!!!"
  default     = "us-west-2"
}

variable "environment" {
  default = "prod"
}

variable "allow_ssh_access" {
  description = "List of CIDR blocks that can access instances via SSH"
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR block for public and private subnets"

  default = {
    "us-west-2a-public"  = "10.0.1.0/24"
    "us-west-2b-public"  = "10.0.3.0/24"
    "us-west-2a-private" = "10.0.2.0/24"
    "us-west-2b-private" = "10.0.4.0/24"
  }
}

variable "external_nameserver" {
  default = "8.8.8.8"
}

variable "extra_packages" {
  description = "Additional packages to install for particular module"

  default = {
    base           = "wget"
    MightyTrousers = "wget bind-utils"
  }
}
