#!/usr/bin/env python3

import psycopg2
import sys
import datetime
import boto3
from botocore.client import Config

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