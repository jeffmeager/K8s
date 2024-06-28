#!/bin/bash

# Variables
MONGO_HOST="localhost"
MONGO_PORT="27017"
BACKUP_DIR="/path/to/backup/dir"
S3_BUCKET="s3://wiztech-docker-tfstate"

# Perform backup
mongodump --host $MONGO_HOST --port $MONGO_PORT --out $BACKUP_DIR

# Upload to S3
aws s3 cp $BACKUP_DIR $S3_BUCKET --recursive --profile devops-lead
