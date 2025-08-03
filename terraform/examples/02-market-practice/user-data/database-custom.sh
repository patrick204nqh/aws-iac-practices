#!/bin/bash
# Custom AMI user-data script
# Docker and images are already pre-installed in the AMI

# Log startup
echo "$(date): Starting database services from custom AMI" >> /var/log/database-startup.log

# The systemd service database-services.service is already enabled in the AMI
# It will automatically start the Docker containers on boot

# Additional logging for debugging
systemctl status database-services.service >> /var/log/database-startup.log 2>&1

# Wait a bit and log container status
sleep 45
echo "$(date): Container status:" >> /var/log/database-startup.log
docker ps >> /var/log/database-startup.log 2>&1

echo "$(date): Database services startup completed" >> /var/log/database-startup.log