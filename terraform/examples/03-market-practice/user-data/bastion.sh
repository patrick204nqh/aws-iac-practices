#!/bin/bash
# Update system
apt-get update -y

# Install useful tools
apt-get install -y git tmux htop netcat-traditional telnet mysql-client postgresql-client

# Create SSH config template for easy access
cat > /home/ubuntu/.ssh/config << 'EOF'
Host webapp
    HostName ${webapp_private_ip}
    User ubuntu
    Port 22
    StrictHostKeyChecking no

Host database
    HostName ${database_private_ip}
    User ubuntu
    Port 22
    StrictHostKeyChecking no
EOF

chown ubuntu:ubuntu /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config

# Create connection test script
cat > /home/ubuntu/test-connections.sh << 'EOF'
#!/bin/bash
echo "=== Testing VPC Connectivity ==="
echo ""
echo "Testing webapp..."
nc -zv ${webapp_private_ip} 22
nc -zv ${webapp_private_ip} 80
echo ""
echo "Testing database..."
nc -zv ${database_private_ip} 22
nc -zv ${database_private_ip} 3306
nc -zv ${database_private_ip} 6379
EOF

chmod +x /home/ubuntu/test-connections.sh