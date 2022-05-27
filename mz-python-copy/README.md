# Python Script to Copy The Content of a Materialize View to S3

## Introduction

[Materialize](https://materialize.com?utm_source=bobbyiliev) is a streaming database for real-time analytics. It was launched in 2019 to address the growing need for the ability to build real-time applications easily and efficiently on streaming data so that businesses can obtain actionable intelligence from streaming data.

This is a simple example of how to copy the content of a Materialize view into a local file and upload it to S3.

## Prerequisites

Before you can run this script, you need to have the following prerequisites:
- [A running Materialize instance](https://materialize.com/docs/install?utm_source=bobbyiliev)
- Python 3.6 or later
- AWS S3 Bucket and credentials

## Install the Python Dependencies

As Materialize is Postgres wire-compatible, we can use the `psycopg2` Python library to connect and execute queries just like we would with a Postgres database.

Start by installing the `psycopg2` Python library:

```
pip3 install psycopg2
```

If you are also planning to upload the data to S3, you will need to install the `boto3` Python library:

```
pip3 install boto3
```

With that done, you can now run the script!

If you are going to upload the data to S3, you will need to create an AWS S3 Bucket and credentials in `~/.aws/credentials`:

```
[default]
aws_access_key_id = <your access key>
aws_secret_access_key = <your secret key>
```

## Creating the Script

Create a new Python script file and paste the following code into it:

```python
#!/usr/bin/env python3

import psycopg2
import sys
import datetime
import boto3
from botocore.client import Config

# Connect to the Materialize database
# Replace the values with your own
dsn = "postgresql://materialize@localhost:6875/materialize?sslmode=disable"
conn = psycopg2.connect(dsn)

# If arg supply don't ask for input
if len(sys.argv) > 1:
    mz_view = sys.argv[1]
else:
    mz_view = input("Enter your view name: ")
    # While empty ask for input
    while mz_view == "":
        mz_view = input("Enter your view name: ")

# Check if view exists
print("Checking if view exists...")
with conn.cursor() as cur:
    try:
        cur.execute("SELECT * FROM " + mz_view + " LIMIT 1")
    except psycopg2.Error as e:
        print("View " + mz_view + " doesn't exist")
        sys.exit(1)

# File name with timestamp without spaces
mz_file = mz_view + "_" + str(datetime.datetime.now()).replace(" ", "_") + ".txt"

print("Dumping view " + mz_view + " to file " + mz_file)
with conn.cursor() as cur:
    cur.execute("SELECT * FROM " + mz_view)
    for row in cur:
        with open(mz_file, 'a') as f:
            f.write(str(row) + '\n')

# Ask if want to upload to S3
if input("Upload to S3? (y/n): ") == "y":
    if len(sys.argv) > 2:
        BUCKET = sys.argv[2]
    else:
        BUCKET = input("Enter your S3 bucket name: ")
        # While empty ask for input
        while BUCKET == "":
            BUCKET = input("Enter your S3 bucket name: ")

    s3 = boto3.resource('s3')
    # MinIo Example:
    # s3 = boto3.resource('s3',
    #                 endpoint_url='http://localhost:9000',
    #                 aws_access_key_id='YOUR-ACCESSKEYID',
    #                 aws_secret_access_key='YOUR-SECRETACCESSKEY',
    #                 config=Config(signature_version='s3v4'),
    #                 region_name='us-east-1')

    print("Uploading file " + mz_file + " to S3 bucket " + BUCKET)
    try:
        s3.Bucket(BUCKET).upload_file(mz_file, "mz_dump/" + mz_file)
    except Exception as e:
        print("Error uploading file to S3: " + str(e))
        sys.exit(1)
```

You can also get the script from [GitHub](https://github.com/bobbyiliev/materialize-tutorials/)

## Running the Script

To run the script, you need to supply the name of the view you want to copy.

```
python3 mz-copy.py
```

You will be asked for the name of the view and the name of the S3 bucket in case you want to upload the data to S3:

```
Enter your view name: my_view
Checking if view exists...
Dumping view test to file my_view_2022-05-27_14:52:02.737658.txt
Upload to S3? (y/n): y
Enter your S3 bucket name: my_bucker
```

You can also specify the name of the view and the S3 bucket as arguments:

```
python3 mz-copy.py my_view my_bucket
```

This will generate a file named `my_view_2022-05-27_14:52:02.737658.txt` and upload it to the S3 bucket `my_bucket`.

## Using MinIO

To use MinIO instead of S3, you can change the `s3 = boto3.resource('s3')` line to:

```
s3 = boto3.resource('s3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='YOUR-ACCESSKEYID',
    aws_secret_access_key='YOUR-SECRETACCESSKEY',
    config=Config(signature_version='s3v4'),
    region_name='us-east-1')
```

For more information on MinIO, please refer to [this article](https://docs.min.io/docs/python-client-api-reference).

## Conclusion

This is a simple example of how to copy the content of a Materialize view into a local file and upload it to S3.

There are plans to add is something similar to Postgres's `COPY` command for exactly this purpose, but in the meantime, you can use this script to dump the data into a local file and upload it to S3.

At the moment you can use `COPY` send the output to `STDOUT` example:

```
COPY (SELECT * FROM some_view) TO STDOUT;
```

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres?utm_source=bobbyiliev)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source?utm_source=bobbyiliev)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views?utm_source=bobbyiliev)
* [`SELECT`](https://materialize.com/docs/sql/select?utm_source=bobbyiliev)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!