# Define the Materialize provider
terraform {
  required_providers {
    materialize = {
      source  = "MaterializeInc/materialize"
      version = "0.0.4"
    }
    # null = {
    #   source = "hashicorp/null"
    #   version = "3.2.1"
    # }
  }
}

# Include aws provider
provider "aws" {
  region = "us-east-1"
}

# Include Materialize provider
provider "materialize" {
  host     = local.materialize_host
  username = local.materialize_username
  password = local.materialize_password
  port     = 6875
  database = "materialize"
}

# Use the materialize ssh module
module "ssh_bastion" {
  source = "git::https://github.com/bobbyiliev/terraform-materialize-ec2-ssh-bastion.git?ref=main"

  aws_region     = local.aws_region
  mz_egress_ips  = local.mz_egress_ips
  vpc_id         = local.vpc_id
  subnet_id      = local.subnet_id
  ssh_public_key = local.ssh_public_key
}

# Create an SSH connection in Materialize
resource "materialize_connection_ssh_tunnel" "example_ssh_connection" {
  name        = "ssh_example_connection"
  schema_name = "public"
  host        = module.ssh_bastion.ssh_bastion_server.public_ip
  port        = 22
  user        = "ubuntu"
}

# Upload the example_ssh_connection.public_key_1 to the EC2 ssh bastion server
# resource "null_resource" "upload_ssh_key" {
#     provisioner "remote-exec" {
#     connection {
#       host = module.ssh_bastion.ssh_bastion_server.public_ip
#       user = "ubuntu"
#       private_key = file("${local.ssh_private_key}")
#     }

#     inline = ["echo 'connected!'"]
#   }
#   provisioner "local-exec" {
#     command = "ssh -i ${local.ssh_private_key} ubuntu@${module.ssh_bastion.ssh_bastion_server.public_ip} 'echo ${materialize_connection_ssh_tunnel.example_ssh_connection.public_key_1} >> ~/.ssh/authorized_keys'"
#   }
# }

output "ssh_connection_details" {
  value       = materialize_connection_ssh_tunnel.example_ssh_connection
}

# Output instructions on how to upload the ssh key
output "upload_ssh_key" {
  value = "To upload the SSH key to the EC2 bastion server run the following command: \n\n ssh -i ${local.ssh_private_key} ubuntu@${module.ssh_bastion.ssh_bastion_server.public_ip} 'echo ${materialize_connection_ssh_tunnel.example_ssh_connection.public_key_1} >> ~/.ssh/authorized_keys'"
}
