# Materialize Terraform Provider + Materialize Module for Amazon MSK

This is an example of how to use the [Materialize Terraform Provider](https://github.com/MaterializeInc/terraform-provider-materialize) to manage your Materialize resources like [connections](https://materialize.com/docs/sql/create-connection/), [sources](https://materialize.com/docs/sql/create-source/), and [clusters](https://materialize.com/docs/sql/create-cluster/) alongside the [Materialize Module for Amazon MSK](https://github.com/MaterializeInc/terraform-aws-msk-privatelink).

The end result is a Materialize cluster that is connected to an Amazon MSK cluster via an AWS PrivateLink connection.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) 0.13 or later
- [Materialize Cloud](https://cloud.materialize.com/) account
- [AWS](https://aws.amazon.com/) account
- [MSK cluster](https://docs.aws.amazon.com/msk/latest/developerguide/create-cluster.html)

## Overview of the Terraform Configuration

The configuration is divided into several sections:

1.  **Define the Materialize provider**: This section specifies the required Materialize provider version and its source.
2.  **Include the AWS provider**: This section configures the AWS provider with the specified region.
3.  **Include the Materialize provider**: This section configures the Materialize provider with connection information, such as host, username, password, port, and database.
4.  **Use the Materialize MSK module**: This section sets up the MSK cluster by providing necessary information such as the cluster name, port, VPC ID, and AWS region.
5.  **Create a PrivateLink connection in Materialize**: This section creates a PrivateLink connection in Materialize by providing the necessary information such as name, schema name, service name, and availability zones.
6.  **Add the Materialize allowed principal to the AWS VPC Endpoint Service**: This section allows the Materialize principal to access the AWS VPC Endpoint Service by providing the VPC Endpoint Service ID and Materialize principal ARN.
7.  **Approve the VPC Endpoint Service connection**: This section instructs you to manually approve the VPC Endpoint Service connection in your AWS account.

## Step-by-step Instructions

### Step 1: Define the Materialize provider

This block specifies the required version of the Materialize provider and its source:

```hcl
terraform {
  required_providers {
    materialize = {
      source = "MaterializeInc/materialize"
      version = "0.0.3"
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


### Step 4: Use the Materialize MSK module

Set up the MSK cluster by providing the necessary information:

```hcl
module "msk" {
    source = "git::https://github.com/MaterializeInc/terraform-aws-msk-privatelink.git?ref=main"

    mz_msk_cluster_name = "your_msk_cluster_name_here"
    mz_msk_cluster_port = 9092
    mz_msk_vpc_id       = "vpc-your_vpc_here"
    aws_region          = "us-east-1"
}
```

### Step 5: Create a PrivateLink connection in Materialize

Create a PrivateLink connection in Materialize:

```hcl
resource "materialize_connection_aws_privatelink" "example_privatelink_connection" {
  name               = "example_privatelink_connection"
  schema_name        = "public"
  service_name       = module.msk.mz_msk_endpoint_service.service_name
  availability_zones = module.msk.mz_msk_azs
}
```

### Step 6: Add the Materialize allowed principal to the AWS VPC Endpoint Service

Allow the Materialize principal to access the AWS VPC Endpoint Service by providing the VPC Endpoint Service ID and Materialize principal ARN:

```hcl
resource "aws_vpc_endpoint_service_allowed_principal" "example_privatelink_connection" {
  vpc_endpoint_service_id = module.msk.mz_msk_endpoint_service.id
  principal_arn           = materialize_connection_aws_privatelink.example_privatelink_connection.principal
}
```
### Step 7: Approve the VPC Endpoint Service connection

After Terraform has successfully created the resources, you will need to approve the VPC Endpoint Service connection in your AWS account:

1.  Sign in to the AWS Management Console.
2.  Navigate to the [VPC Dashboard](https://console.aws.amazon.com/vpc/).
3.  In the left navigation pane, click on **Endpoint Services**.
4.  Find the endpoint service associated with your MSK cluster.
5.  In the **Actions** menu, click **Manage Connections**.
6.  Select the pending connection request and click **Approve**.

Once the connection is approved, Materialize can access the MSK cluster over the PrivateLink connection. You can now create a Kafka source in Materialize and start streaming data from your MSK cluster.

## Complete Example

Check out the [`main.tf`](main.tf) file in this repository for a complete example of how to use the Materialize Terraform Provider and the Materialize Terraform Module for AWS PrivateLink and MSK together.
