LocalStack provides a fully functional AWS cloud stack that can be run locally for development and testing purposes without using the actual AWS cloud services.

## Install Localstack and run

```sh
pip install localstack
localstack start -d
```

To get the status of each service

```sh
localstack status services
```

## Run via Docker compose

** `docker-compose.yml` for Localstack S3, SQS and DynamoDB **

```Docker
version: "3.9"

services:
  localstack:
    container_name: "${LOCALSTACK_DOCKER_NAME-localstack_main}"
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
      - "4510-4559:4510-4559"
    environment:
      - DEBUG=1
      - DOCKER_HOST=unix:///var/run/docker.sock
			- SERVICES=s3,sqs,dynamodb
    volumes:
      - "${LOCALSTACK_VOLUME_DIR:-./volume}:/var/lib/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
			- "./data:/tmp/localstack"
		healthcheck:
			test:
        - CMD
        - bash
        - -c
        - awslocal dynamodb list-tables
          && awslocal s3 ls
          && awslocal sqs list-queues
			interval: 10s
			timeout: 5s
			retries: 5
```

### Populating data into localstack S3 on `docker compose up`

Add these two lines to the `volumes` in the `docker-compose.yml` (assuming the data/files we want to upload to loaclstack S3 are in `s3_data` folder)

```
      - "./.localstack:/docker-entrypoint-initaws.d"
      - "./s3_data:/s3_data" # location of files used to pre-populate the Localstack S3 bucket
```

Then create `.localstack` directory, and inside this folder create a `bucket_policy.json` with the following AWS policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::mock-bucket/*"
        },
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::another-mock-bucket/*"
        }
    ]
}
```

and create a shell script (e.g. `create_and_populate_bucket.sh`) with commands to create and upload/synchronise the localstack S3 bucket with local data:

```
awslocal s3api create-bucket --bucket mock-bucket
awslocal s3api put-bucket-policy --bucket mock-bucket --policy ./bucket_policy.json
awslocal s3 sync /s3_data s3://mock-bucket
```
