provider "aws" {
  region  = "us-east-1"
  version = "~> 2.22.0"
}

terraform {
  required_version = "0.11.14"
}

data "external" "get-my-ip" {
  program = ["sh", "getmyip.sh"]
}

module "my-instance" {
  source = "./dev-machine"
  my-ip = "${data.external.get-my-ip.result.ip}"
  name  = "dev-machine"
}
