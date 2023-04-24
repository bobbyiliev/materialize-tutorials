# Define the Materialize provider
terraform {
  required_providers {
    materialize = {
      source = "MaterializeInc/materialize"
      version = "0.0.3"
    }
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

# Use the materialize msk module
module "msk" {
    source = "git::https://github.com/MaterializeInc/terraform-aws-msk-privatelink.git?ref=main"

    mz_msk_cluster_name = "example-msk-cluster"
    mz_msk_cluster_port = 9092
    mz_msk_vpc_id       = "vpc-1234567890"
    aws_region          = "us-east-1"
}

# Create a PrivateLink connection in Materialize
resource "materialize_connection_aws_privatelink" "example_privatelink_connection" {
  name               = "example_privatelink_connection"
  schema_name        = "public"
  service_name       = module.msk.mz_msk_endpoint_service.service_name
  availability_zones = module.msk.mz_msk_azs
}

# Add the Materialize allowed principal to the AWS VPC Endpoint Service
resource "aws_vpc_endpoint_service_allowed_principal" "example_privatelink_connection" {
  vpc_endpoint_service_id = module.msk.mz_msk_endpoint_service.id
  principal_arn           = materialize_connection_aws_privatelink.example_privatelink_connection.principal
}

# Finally go to your AWS account and approve the VPC Endpoint Service connection
