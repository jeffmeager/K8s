#!/bin/bash

# Variables — can be passed in from Terraform/templatefile()
MONGODB_BINDIP="$${mongodb_bind_ip:-0.0.0.0}"
MONGO_USERNAME="$${mongodb_username}"
MONGO_PASSWORD="$${mongodb_password}"
BACKUP_BUCKET="$${backup_bucket}"

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

apt-get update
apt-get install -y mongodb-org=4.0.28 mongodb-org-server=4.0.28 mongodb-org-shell=4.0.28 mongodb-org-mongos=4.0.28 mongodb-org-tools=4.0.28 awscli

# Update mongod.conf to bind to desired IP
sed -i "s/^  bindIp: .*/  bindIp: $${MONGODB_BINDIP}/" /etc/mongod.conf

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
mongo --eval "db.getSiblingDB('admin').createUser({user: '$${MONGO_USERNAME}', pwd: '$${MONGO_PASSWORD}', roles:[{role:'root', db:'admin'}]})"

# Inject backup.sh script
cat <<'EOD' > /home/challengeuser/backup.sh
#!/bin/bash

# Variables
MONGO_HOST="localhost"
MONGO_PORT="27017"
BACKUP_DIR="/home/challengeuser/mongo_backup"
S3_BUCKET="s3://$${BACKUP_BUCKET}"

# Perform backup
mongodump --host $MONGO_HOST --port $MONGO_PORT --out $BACKUP_DIR

# Upload to S3
aws s3 cp $BACKUP_DIR $S3_BUCKET --recursive
EOD

# Replace placeholders in backup.sh
sed -i "s|\$${BACKUP_BUCKET}|$${BACKUP_BUCKET}|" /home/challengeuser/backup.sh

# Set permissions
chown challengeuser:challengeuser /home/challengeuser/backup.sh
chmod +x /home/challengeuser/backup.sh

# Add twice-daily cron job for backup.sh (runs hourly)
0 * * * * /home/challengeuser/backup.sh >> /home/challengeuser/backup.log 2>&1

