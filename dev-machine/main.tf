resource "tls_private_key" "dev_machine" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.dev_machine.private_key_pem}\" > ${var.name}-identity.pem; chmod 400 ${var.name}-identity.pem"
  }
}

data "aws_ami" "latest_ubuntu" {
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

resource "aws_key_pair" "dev_machine" {
  public_key = tls_private_key.dev_machine.public_key_openssh
}

resource "aws_security_group" "dev_machine" {
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

resource "aws_instance" "dev_machine" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.dev_machine.key_name
  associate_public_ip_address = true
  security_groups = [aws_security_group.dev_machine.name]
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
    command = "echo \"${aws_instance.dev_machine.public_ip}\" > ip_address.txt"
  }

  provisioner "local-exec" {
    command = "echo \"${templatefile("${path.module}/connect.sh.tmpl", { identity = "${var.name}-identity.pem", public_ip = "${aws_instance.dev_machine.public_ip}"})}\" > connect-to-${var.name}.sh; chmod +x connect-to-${var.name}.sh"
  }

  tags = {
    Name = var.name
  }
}

