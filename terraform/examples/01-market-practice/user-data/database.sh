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
usermod -a -G docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker-compose.yml
cat > /home/ubuntu/docker-compose.yml << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: market_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: marketroot123
      MYSQL_DATABASE: market
      MYSQL_USER: market_user
      MYSQL_PASSWORD: market_pass123
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: market_redis
    restart: always
    command: redis-server --requirepass market_redis123
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  mysql_data:
  redis_data:
EOF

# Start services
cd /home/ubuntu
docker-compose up -d

# Wait for services to be healthy
sleep 30

# Log status
docker ps > /var/log/database-status.log
docker-compose logs > /var/log/database-logs.log