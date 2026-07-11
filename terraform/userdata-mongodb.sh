#!/bin/bash
set -euxo pipefail

cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

sudo yum install -y mongodb-org

sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

sudo systemctl enable --now mongod

until mongosh --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
  sleep 1
done

mongosh --quiet --eval '
db.getSiblingDB("starsigns").createUser({
  user: "${mongo_app_user}",
  pwd: "${mongo_app_password}",
  roles: [{ role: "readWrite", db: "starsigns" }]
})
'

cat <<'EOF' | sudo tee -a /etc/mongod.conf > /dev/null

security:
  authorization: enabled
EOF

sudo systemctl restart mongod

cat > /usr/local/bin/mongodb-backup.sh <<'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
WORKDIR=$(mktemp -d)
ARCHIVE="mongodb-backup-$TIMESTAMP.tar.gz"

mongodump --db starsigns --username "${mongo_app_user}" --password "${mongo_app_password}" --authenticationDatabase starsigns --out "$WORKDIR/dump"
tar -czf "$WORKDIR/$ARCHIVE" -C "$WORKDIR" dump

aws s3 cp "$WORKDIR/$ARCHIVE" "s3://${bucket_name}/$ARCHIVE"

rm -rf "$WORKDIR"
EOF
chmod +x /usr/local/bin/mongodb-backup.sh

cat > /etc/systemd/system/mongodb-backup.service <<'EOF'
[Unit]
Description=Back up MongoDB to S3
After=mongod.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mongodb-backup.sh
EOF

cat > /etc/systemd/system/mongodb-backup.timer <<'EOF'
[Unit]
Description=Run MongoDB S3 backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mongodb-backup.timer
