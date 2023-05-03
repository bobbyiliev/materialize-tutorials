# Materialize Terraform Provider + Materialize Module for EC2 SSH Bastion

This is an example of how to use the [Materialize Terraform Provider](https://github.com/MaterializeInc/terraform-provider-materialize) to manage your Materialize resources like [connections](https://materialize.com/docs/sql/create-connection/), [sources](https://materialize.com/docs/sql/create-source/), and [clusters](https://materialize.com/docs/sql/create-cluster/) alongside the [Materialize Module EC2 SSH Bastion](https://github.com/bobbyiliev/terraform-materialize-ec2-ssh-bastion).

The end result is an EC2 SSH Bastion host in your AWS account and an SSH connection in Materialize that you can use to connect to your sources.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) 0.13 or later
- [Materialize Cloud](https://cloud.materialize.com/) account
- [AWS](https://aws.amazon.com/) account

## Overview of the Terraform Configuration

The configuration is divided into several sections:

1.  **Define the Materialize provider**
2.  **Include the AWS provider**
3.  **Include the Materialize provider**
4.  **Use the Materialize EC2 SSH Bastion module**

## Step-by-step Instructions

### Step 1: Define the Materialize provider

This block specifies the required version of the Materialize provider and its source:

```hcl
terraform {
  required_providers {
    materialize = {
      source = "MaterializeInc/materialize"
      version = "0.0.4"
    }
  }
}
```

### Step 2: Include the AWS provider

Configure the AWS provider with the specified region:

```hcl
provider "aws" {
    region = "us-east-1"
}
```

### Step 3: Include the Materialize provider

Configure the Materialize provider with the necessary connection information:

```hcl
provider "materialize" {
  host     = local.materialize_host
  username = local.materialize_username
  password = local.materialize_password
  port     = 6875
  database = "materialize"
}
```


### Step 4: Use the Materialize EC2 SSH Bastion module

Use the Materialize EC2 SSH Bastion module to create an EC2 instance that can be used to create an SSH connection in Materialize:

```hcl
module "ssh_bastion" {
  source = "git::https://github.com/bobbyiliev/terraform-materialize-ec2-ssh-bastion.git?ref=main"

  aws_region     = local.aws_region
  mz_egress_ips  = local.mz_egress_ips
  vpc_id         = local.vpc_id
  subnet_id      = local.subnet_id
  ssh_public_key = local.ssh_public_key
}
```

Define the following variables in your `locals.tf` file:

```hcl
locals {
  aws_region     = "us-east-1"
  mz_egress_ips  = ["1.2.3.4/32", "4.3.2.1/32"]
  vpc_id         = "vpc-1234567890"
  subnet_id      = "subnet-1234567890"
  ssh_public_key = "ssh-rsa AAAAB..."
}
```

### Step 5: Create an SSH connection in Materialize

Create an SSH connection in Materialize using the `materialize_connection` resource:

```hcl
resource "materialize_connection_ssh_tunnel" "example_ssh_connection" {
  name        = "ssh_example_connection"
  schema_name = "public"
  host        = module.ssh_bastion.ssh_bastion_server.public_ip
  port        = 22
  user        = "ubuntu"
}
```

Then to get the public SSH key of the connection, you can use the following output:

```hcl
output "example" {
  value       = materialize_connection_ssh_tunnel.example_ssh_connection
}
```

### Step 6: Upload the Materialize SSH key to the EC2 instance

To upload the Materialize SSH key to the EC2 instance, you can get the public key of the connection and then use it to upload the key to the EC2 instance.

You can use the following output to get the command that you need to run:

```hcl
output "upload_ssh_key" {
  value = "To upload the SSH key to the EC2 bastion server run the following command: \n\n ssh -i ${local.ssh_private_key} ubuntu@${module.ssh_bastion.ssh_bastion_server.public_ip} 'echo ${materialize_connection_ssh_tunnel.example_ssh_connection.public_key_1} >> ~/.ssh/authorized_keys'"
}
```

## Complete Example

Check out the [`main.tf`](main.tf) file in this repository for a complete example of how to use the Materialize Terraform Provider and the Materialize EC2 SSH Bastion Terraform Module.
