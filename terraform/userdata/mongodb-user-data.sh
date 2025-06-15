#!/bin/bash

# Static values and Terraform-injected values
MONGODB_BINDIP="0.0.0.0"
MONGODB_USERNAME="${mongodb_username}"
MONGODB_PASSWORD="${mongodb_password}"
BACKUP_BUCKET="${backup_bucket}"

# Install dependencies
apt-get update -y
apt-get install -y gnupg wget curl awscli mongodb-org-tools

# Create challengeuser
useradd -m -s /bin/bash challengeuser

# Add challengeuser to the sudo group *without* requiring a password
usermod -aG sudo challengeuser
echo "challengeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/challengeuser

# Setup SSH authorized keys
mkdir -p /home/challengeuser/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiblVhQ+PQ9yB/M6KkhtMVNUP6/gYz65HuEB2psjyk55VnZUWZtPuiYeKTyT+ggK5XRWHBjgZERGn2yx1YB+BxOu6cUkPiJsUDlndHrHjafh2WfNcnauoDnLyHuvxFofSW+lsGoG9die9Tubc1mEqkTqlvZaUbKS9bTcpVBwbpVD5qoWRRceBfiflzFqJNkjIWzCRxLxf6qxeyhdYo0F3CdvsDZHEG/UR4FkFRUZ12u5cxE6rkUyIzkC44uNqo3ZUUoSgi3BuKFN1py2mEtGip4LKLy22bucNfuWITm+T5vWcdtmAGKXCC63G61y3C4VCxctWLGPlDG4hiWtqmPXeT user@host" > /home/challengeuser/.ssh/authorized_keys
chown -R challengeuser:challengeuser /home/challengeuser/.ssh
chmod 700 /home/challengeuser/.ssh
chmod 600 /home/challengeuser/.ssh/authorized_keys

# Lock ubuntu user
passwd -l ubuntu

# Install MongoDB 4.0 (Disabling GPG Check - UNSAFE!)
echo "deb [trusted=yes arch=amd64] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

apt-get update -y
apt-get install -y amazon-cloudwatch-agent awscli jq
apt-get install -y mongodb-org=4.0.28 mongodb-org-server=4.0.28 mongodb-org-shell=4.0.28 mongodb-org-mongos=4.0.28 mongodb-org-tools=4.0.28
# Update mongod.conf to bind to 0.0.0.0
sed -i "s/^  bindIp: .*/  bindIp: 0.0.0.0/" /etc/mongod.conf

# Start MongoDB
systemctl restart mongod
systemctl enable mongod

# Wait for mongod to start
for i in {1..30}; do
  if nc -z localhost 27017; then
    echo "MongoDB is up!"
    break
  fi
  echo "Waiting for MongoDB to start ($i/30)..."
  sleep 1
done

# Create admin user
mongo --eval "db.getSiblingDB('admin').createUser({user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles:[{role:'root', db:'admin'}]})"

# Stop mongod to enable authentication
systemctl stop mongod

# Enable MongoDB authentication
echo "Enabling MongoDB authentication..."
echo "
security:
  authorization: enabled
" >> /etc/mongod.conf

# Start MongoDB with authentication enabled
systemctl start mongod

# Inject backup.sh script
cat <<'EOD' > /home/challengeuser/backup.sh
#!/bin/bash

set -e

# AWS configuration
SECRET_NAME="webapp-secrets"
REGION="us-east-1"

# Timestamp for backup folder
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Backup path (new folder per run)
BACKUP_DIR="/home/challengeuser/mongo_backup/${TIMESTAMP}"
S3_BUCKET="s3://challenge-docker-backups"

# Create the timestamped backup directory
mkdir -p "$BACKUP_DIR"

# Fetch MongoDB URI from Secrets Manager
MONGODB_URI=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text | jq -r '."mongodb-uri"')

# Run mongodump using the URI
mongodump --uri="$MONGODB_URI" --out "$BACKUP_DIR"

# Upload backup to S3
aws s3 cp "$BACKUP_DIR" "$S3_BUCKET/${TIMESTAMP}" --recursive

EOD

# Replace placeholders in backup.sh
sed -i "s|\$${BACKUP_BUCKET}|${backup_bucket}|" /home/challengeuser/backup.sh

# Set permissions
chown challengeuser:challengeuser /home/challengeuser/backup.sh
chmod +x /home/challengeuser/backup.sh

# Add cron job for backup.sh (runs hourly)
echo "0 * * * * /home/challengeuser/backup.sh >> /home/challengeuser/backup.log 2>&1" | crontab -u challengeuser -


# Install and configure CloudWatch Agent
 cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
 {
   "logs": {
     "logs_collected": {
       "files": {
         "collect_list": [
           {
             "file_path": "/var/log/mongodb/mongod.log",
             "log_group_name": "/mongodb/logs",
             "log_stream_name": "{instance_id}"
           },
           {
             "file_path": "/var/log/syslog",
             "log_group_name": "/syslog",
             "log_stream_name": "{instance_id}"
           }
         ]
       }
     }
   }
 }
 EOF

 /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
   -a fetch-config \
   -m ec2 \
   -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
   -s
