resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.private_key.private_key_pem}\" > identity.pem; chmod 400 identity.pem"
  }
}

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon-linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # hvm > pv
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_key_pair" "my-key-pair" {
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "aws_security_group" "security_grp" {
  name = "allow_ssh_from_me"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["${var.my-ip}/32"]
  }

  # allow all user ports for dev
  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev-machine" {
  #ami           = "${data.aws_ami.amazon-linux.id}"
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.my-key-pair.key_name

  associate_public_ip_address = true

  security_groups = [aws_security_group.security_grp.name]

  user_data = <<EOF
#!/bin/bash
sudo apt -y update && sudo apt -y upgrade
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt -y update
apt-cache policy docker-ce
sudo apt -y install docker-ce
sudo usermod -aG docker ubuntu
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | sudo bash
EOF


  provisioner "local-exec" {
    command = "echo \"${aws_instance.dev-machine.public_ip}\" > ip_address.txt"
  }

  tags = {
    Name = var.name
  }
}

