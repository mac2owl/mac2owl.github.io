#!/bin/bash

awslocal s3api create-bucket --bucket mock-bucket
awslocal s3api create-bucket --bucket another-mock-bucket

awslocal s3api put-bucket-policy --bucket mock-bucket --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicReadGetObject\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::mock-bucket/*\"}]}"
awslocal s3api put-bucket-policy --bucket another-mock-bucket --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicReadGetObject\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::another-mock-bucket/*\"}]}"

awslocal s3 sync /s3_data s3://mock-bucket
awslocal s3 sync /another_s3_data s3://another-mock-bucket