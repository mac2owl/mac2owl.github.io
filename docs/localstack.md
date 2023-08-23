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
      - "./.localstack:/docker-entrypoint-initaws.d"
      - "./s3_data:/s3_data" # location of files used to pre-populate the Localstack S3 bucket
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
