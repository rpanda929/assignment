#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update and install packages (Ubuntu)
apt-get update -y
apt-get install -y nginx awscli curl

# Write index.html from base64 payload
mkdir -p /var/www/html
echo "${index_b64}" | base64 -d > /var/www/html/index.html
chown www-data:www-data /var/www/html/index.html
chmod 0644 /var/www/html/index.html

# Enable + start nginx
systemctl enable nginx
systemctl restart nginx

# Upload index.html to S3 (role credentials will be used)
aws s3 cp /var/www/html/index.html "s3://${s3_bucket}/${s3_prefix}" --region "${region}" || true

# Discover public IPv4 via Instance Metadata Service (IMDS)
IPV4="$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/public-ipv4 || echo unknown)"
URL="http://${IPV4}"

# Print handy URL into MOTD and a log file
echo "Your page should be live at: ${URL}" | tee -a /etc/motd /var/log/user-data-final-url.log || true

