provider "aws" {
  region = "us-west-2"
}

data "aws_vpc" "management_layer" {
  id = "vpc-d2f354b4"
}

data "external" "example" {
  program = ["ruby", "${path.module}/custom_data_source.rb"]
}

resource "tls_private_key" "example" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "${var.vpc_cidr}"
}

resource "aws_vpc_peering_connection" "my_vpc-management" {
  peer_vpc_id = "${data.aws_vpc.management_layer.id}"
  vpc_id      = "${aws_vpc.my_vpc.id}"
  auto_accept = true
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  cidr_block              = "${lookup(var.subnet_cidrs, "public")}"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "default" {
  name        = "Default SG"
  description = "Allow SSH access"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress = {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.allow_ssh_access}"
  }
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# the Internet gateway is responsible for enabling Internet connectivity inside VPC

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
}

resource "aws_default_route_table" "default_routing" {
  default_route_table_id = "${aws_vpc.my_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

#resource "aws_ami_role_policy" "s3-assets-all" {
#    name = "s3=assets@all"
#    role = "${aws_ami_role.app-production.id}"
#    policy =  "${file("policies/s3=assets@all.json")}"
#}

module "mighty_trousers" {
  source              = "./modules/application"
  vpc_id              = "${aws_vpc.my_vpc.id}"
  subnet_id           = "${aws_subnet.public.id}"
  name                = "MightyTrousers-${data.external.example.result.owner}"
  keypair             = "${aws_key_pair.terraform.key_name}"
  environment         = "${var.environment}"
  extra_sgs           = ["${aws_security_group.default.id}"]
  extra_packages      = "${lookup(var.extra_packages,"MightyTrousers")}"
  external_nameserver = "${var.external_nameserver}"
}

output "hostname" {
  value = "${module.mighty_trousers.hostname}"
}

output "mighty_trousers_public_ip" {
  value = "${module.mighty_trousers.public_ip}"
}
