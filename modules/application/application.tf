resource "aws_security_group" "allow_http" {
  name        = "${var.name} allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "app-ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["ubuntu-16-base-puppet*"]
  }
}

resource "random_id" "hostname" {
  keepers {
    ami_id = "ami-835b4efa"
  }

  byte_length = 4
}

resource "random_shuffle" "hostname_creature" {
  input        = ["griffin", "gargoyle", "dragon"]
  result_count = 1
}

resource "random_id" "hostname_random" {
  byte_length = 4
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh.tpl")}"

  vars {
    packages   = "${var.extra_packages}"
    nameserver = "${var.external_nameserver}"
    hostname   = "${random_shuffle.hostname_creature.result[0]}${random_id.hostname.b64}"
  }
}

# Providing AMI through consul
#provider "consul" { 
#    address = "consul.example.com:80" 
#    datacenter = "frankfurt" 
#} 
#data "consul_keys" "amis" { 
#    # Read the launch AMI from Consul 
#    key { 
#        name = "mighty_trousers" 
#        path = "ami" 
#    } 
#} 

resource "aws_instance" "app-server" {
  #ami = "ami-835b4efa"
  ami = "${data.aws_ami.app-ami.id}"

  #  ami = "${consul_keys.amis.var.mighty_trousers}"
  instance_type = "${lookup(var.instance_type, var.environment)}"

  subnet_id              = "${element(var.subnets, count.index%2)}"
  vpc_security_group_ids = ["${distinct(concat(var.extra_sgs, aws_security_group.allow_http.*.id))}"]
  user_data              = "${data.template_file.user_data.rendered}"
  key_name               = "${var.keypair}"

  tags {
    Name = "${var.name}"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["user_data"]
  }

  count = "${var.instance_count}"
}

resource "null_resource" "app_server_provisioner" {
  triggers {
    server_id = "${element(aws_instance.app-server.*.public_ip, count.index)}"
  }

  connection {
    user = "ubuntu"
    host = "${element(aws_instance.app-server.*.public_ip, count.index)}"
  }

  provisioner "file" {
    source      = "${path.module}/setup.pp"
    destination = "/tmp/setup.pp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo puppet apply /tmp/setup.pp",
    ]
  }

  count = "${var.instance_count}"
}

resource "aws_elb" "load-balancer" {
  name            = "application-load-balancer"
  subnets         = ["${var.subnets}"]
  security_groups = ["${aws_security_group.allow_http.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances = ["${aws_instance.app-server.*.id}"]
  count     = "${var.instance_count > 1 ? 1 : 0}"
}

output "hostname" {
  value = "${aws_instance.app-server.private_dns}"
}

output "public_ip" {
  value = "${join(",", aws_instance.app-server.*.public_ip)}"
}

output "app_address" {
  value = "${aws_elb.load-balancer.dns_name}"
}
