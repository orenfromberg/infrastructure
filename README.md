# infrastructure

## dev-machine

This module will provision an EC2 instance running ubuntu that can be used for web development. 

To use it, get your ip address and add the following terraform:

```terraform
module "my-instance" {
  source = "git@github.com:orenfromberg/infrastructure.git//dev-machine?ref=tags/v0.0.5"
  my-ip = "71.104.71.56"
  name  = "my-dev-machine"
}
```
Make sure you are using the desired tagged release.

then run:
```sh
$ terraform init
$ terraform apply
```

Once the command is complete, you'll have an identity file `my-dev-machine-identity.pem` and a script called `connect-to-my-dev-machine.sh` created in your local directory.

Now ssh to the instance using the following command:
```sh
$ ./connect-to-my-dev-machine.sh
```
