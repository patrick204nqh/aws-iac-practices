#!/bin/bash
# Update system
apt-get update -y

# Install Docker
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker

# Create services configuration
mkdir -p /opt/webapp
cat > /opt/webapp/services.json << 'EOF'
{
  "services": {
    "database": {
      "host": "${database_private_ip}",
      "port": 3306,
      "username": "market_user",
      "password": "market_pass123",
      "database": "market"
    },
    "cache": {
      "host": "${database_private_ip}",
      "port": 6379,
      "password": "market_redis123"
    }
  }
}
EOF

# Run simple-webapp container
docker run -d \
  --name simple-webapp \
  --restart unless-stopped \
  -p 80:80 \
  -p 61208:61208 \
  -v /opt/webapp/services.json:/app/config/services.json:ro \
  ghcr.io/patrick204nqh/simple-webapp:latest

# Log container status
docker ps > /var/log/webapp-status.log