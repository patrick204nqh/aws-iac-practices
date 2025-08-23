# Database Management Guide - RDS & ElastiCache

This guide covers day-to-day management, monitoring, and disaster recovery procedures for the Amazon RDS MySQL and ElastiCache Redis services in the market-practice infrastructure.

## Table of Contents

1. [Daily Operations](#daily-operations)
2. [Monitoring & Alerting](#monitoring--alerting)
3. [Backup & Recovery](#backup--recovery)
4. [Disaster Recovery](#disaster-recovery)
5. [Scaling Operations](#scaling-operations)
6. [Security Management](#security-management)
7. [Troubleshooting](#troubleshooting)

## Daily Operations

### RDS MySQL Management

#### Connection Information
```bash
# Get connection details from Terraform outputs
terraform output database_info

# Connection example
mysql -h <rds-endpoint> -u admin -p market_db
```

#### Common Administrative Tasks
```sql
-- Check database status
SHOW STATUS;
SHOW PROCESSLIST;

-- Database size monitoring
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables 
GROUP BY table_schema;

-- Performance monitoring
SELECT * FROM performance_schema.events_statements_summary_by_digest 
ORDER BY avg_timer_wait DESC LIMIT 10;
```

### ElastiCache Redis Management

#### Connection Information
```bash
# Get Redis endpoint
terraform output database_info

# Connect using redis-cli (from bastion or webapp)
redis-cli -h <redis-endpoint> -p 6379
```

#### Common Redis Commands
```bash
# Check Redis status
INFO server
INFO memory
INFO replication

# Monitor performance
MONITOR
INFO stats

# Check key usage
DBSIZE
MEMORY USAGE <key>
```

## Monitoring & Alerting

### CloudWatch Metrics to Monitor

#### RDS MySQL Metrics
```bash
# Key metrics to set up alarms for:
- DatabaseConnections > 80% of max_connections
- CPUUtilization > 80%
- FreeableMemory < 512MB
- FreeStorageSpace < 2GB
- ReadLatency > 200ms
- WriteLatency > 200ms
```

#### ElastiCache Redis Metrics
```bash
# Key metrics to set up alarms for:
- CPUUtilization > 80%
- DatabaseMemoryUsagePercentage > 80%
- CurrConnections approaching max connections
- Evictions > 0 (indicates memory pressure)
- NetworkBytesIn/Out for traffic monitoring
```

### Setting Up CloudWatch Alarms
```bash
# Example: RDS CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-High-CPU" \
  --alarm-description "RDS CPU utilization high" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=market-staging-mysql \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:region:account:topic-name
```

## Backup & Recovery

### RDS MySQL Backups

#### Automated Backups
- **Staging**: 1-day retention (cost optimized)
- **Production**: 7-day retention (compliance ready)
- **Backup Window**: 03:00-04:00 UTC (low traffic period)

#### Manual Snapshots
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier market-staging-mysql \
  --db-snapshot-identifier market-staging-mysql-manual-$(date +%Y%m%d-%H%M)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier market-staging-mysql

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier market-staging-mysql-restored \
  --db-snapshot-identifier market-staging-mysql-manual-20231201-1200
```

#### Point-in-Time Recovery
```bash
# Restore to specific time (within backup retention window)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier market-staging-mysql \
  --target-db-instance-identifier market-staging-mysql-pitr \
  --restore-time 2023-12-01T10:30:00.000Z
```

### ElastiCache Redis Backups

#### Automated Snapshots
- **Staging**: 1 snapshot retained
- **Production**: 5 snapshots retained
- **Snapshot Window**: 03:00-05:00 UTC

#### Manual Snapshots
```bash
# Create manual snapshot
aws elasticache create-snapshot \
  --replication-group-id market-staging-redis \
  --snapshot-name market-staging-redis-manual-$(date +%Y%m%d-%H%M)

# List snapshots
aws elasticache describe-snapshots \
  --replication-group-id market-staging-redis

# Restore from snapshot (requires new cluster)
aws elasticache create-replication-group \
  --replication-group-id market-staging-redis-restored \
  --replication-group-description "Restored Redis cluster" \
  --snapshot-name market-staging-redis-manual-20231201-1200
```

## Disaster Recovery

### RDS MySQL Disaster Recovery

#### Multi-AZ Failover (Production Only)
```bash
# Production automatically handles failover with Multi-AZ
# Monitor failover process
aws rds describe-events \
  --source-identifier market-prod-mysql \
  --source-type db-instance \
  --start-time 2023-12-01T00:00:00Z

# Force failover for testing
aws rds reboot-db-instance \
  --db-instance-identifier market-prod-mysql \
  --force-failover
```

#### Cross-Region Disaster Recovery
```bash
# Create read replica in different region
aws rds create-db-instance-read-replica \
  --db-instance-identifier market-prod-mysql-dr \
  --source-db-instance-identifier arn:aws:rds:source-region:account:db:market-prod-mysql \
  --db-instance-class db.t3.small

# Promote read replica to standalone database (during disaster)
aws rds promote-read-replica \
  --db-instance-identifier market-prod-mysql-dr
```

### ElastiCache Redis Disaster Recovery

#### Redis Data Persistence
```bash
# Redis data is ephemeral, recovery strategies:
# 1. Restore from latest snapshot
# 2. Rebuild cache from primary data source (MySQL)
# 3. Use multi-AZ replication in production

# Emergency cache rebuilding script example
#!/bin/bash
echo "Rebuilding Redis cache from MySQL..."
# Application-specific cache warming logic
# This should be implemented in your application
curl -X POST http://webapp-endpoint/admin/rebuild-cache
```

#### Regional Failover
```bash
# For cross-region DR, set up Redis in secondary region
# Update application configuration to point to DR Redis
# This requires application-level logic to handle failover
```

### Complete Infrastructure Recovery

#### Recovery Time Objectives (RTO)
- **Staging**: 2-4 hours (acceptable for development)
- **Production**: 15-30 minutes (with Multi-AZ RDS)

#### Recovery Point Objectives (RPO)
- **Staging**: 24 hours (daily backups)
- **Production**: 5 minutes (automated backups with Multi-AZ)

#### Full Environment Recreation
```bash
# Emergency: Recreate entire infrastructure from scratch
cd terraform/examples/03-market-practice

# 1. Update terraform.tfvars with new passwords if needed
# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Restore RDS from latest snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier market-staging-mysql \
  --db-snapshot-identifier <latest-snapshot-id>

# 4. Restore Redis from latest snapshot
aws elasticache create-replication-group \
  --replication-group-id market-staging-redis \
  --replication-group-description "Restored from backup" \
  --snapshot-name <latest-snapshot-id>

# 5. Update DNS/load balancer to point to new infrastructure
```

## Scaling Operations

### RDS MySQL Scaling

#### Vertical Scaling (Instance Size)
```bash
# Scale up RDS instance
aws rds modify-db-instance \
  --db-instance-identifier market-prod-mysql \
  --db-instance-class db.t3.medium \
  --apply-immediately

# Update Terraform configuration
# In locals.tf, update rds_instance_class for production
# Then run: terraform plan && terraform apply
```

#### Storage Scaling
```bash
# RDS automatically scales storage up to max_allocated_storage
# To increase the maximum:
aws rds modify-db-instance \
  --db-instance-identifier market-prod-mysql \
  --max-allocated-storage 200 \
  --apply-immediately
```

#### Read Replicas
```bash
# Add read replica for read scaling
aws rds create-db-instance-read-replica \
  --db-instance-identifier market-prod-mysql-read-1 \
  --source-db-instance-identifier market-prod-mysql \
  --db-instance-class db.t3.small
```

### ElastiCache Redis Scaling

#### Vertical Scaling
```bash
# Scale Redis node type
aws elasticache modify-replication-group \
  --replication-group-id market-prod-redis \
  --cache-node-type cache.t3.small \
  --apply-immediately
```

#### Horizontal Scaling (Add Replicas)
```bash
# Increase replica count for production
aws elasticache increase-replica-count \
  --replication-group-id market-prod-redis \
  --new-replica-count 2 \
  --apply-immediately
```

## Security Management

### RDS Security

#### Password Rotation
```bash
# Rotate RDS password
aws rds modify-db-instance \
  --db-instance-identifier market-prod-mysql \
  --master-user-password "NewSecurePassword123!" \
  --apply-immediately

# Update Terraform variable and apply
# terraform apply -var="db_password=NewSecurePassword123!"
```

#### SSL/TLS Configuration
```sql
-- Verify SSL is enabled
SHOW VARIABLES LIKE 'have_ssl';

-- Force SSL connections
-- Add require_secure_transport=ON to parameter group
```

### ElastiCache Security

#### Access Control
```bash
# Redis is secured via VPC security groups
# No authentication enabled for simplicity in this example
# For production, consider enabling AUTH token:

aws elasticache modify-replication-group \
  --replication-group-id market-prod-redis \
  --auth-token "YourRedisAuthToken" \
  --auth-token-update-strategy ROTATE
```

## Troubleshooting

### Common RDS Issues

#### High CPU Usage
```sql
-- Find slow queries
SELECT * FROM performance_schema.events_statements_summary_by_digest 
WHERE avg_timer_wait > 1000000000 -- 1 second
ORDER BY avg_timer_wait DESC;

-- Check for long-running queries
SHOW PROCESSLIST;
```

#### Connection Issues
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <rds-security-group-id>

# Test connectivity from webapp
telnet <rds-endpoint> 3306

# Check parameter group settings
aws rds describe-db-parameters --db-parameter-group-name <parameter-group-name>
```

### Common Redis Issues

#### Memory Issues
```bash
# Check memory usage
redis-cli -h <redis-endpoint> INFO memory

# Check for memory pressure
redis-cli -h <redis-endpoint> INFO stats | grep evicted

# Clear cache if needed (DANGEROUS - data loss)
redis-cli -h <redis-endpoint> FLUSHALL
```

#### Connection Issues
```bash
# Test Redis connectivity
redis-cli -h <redis-endpoint> ping

# Check current connections
redis-cli -h <redis-endpoint> INFO clients
```

### Emergency Contacts & Procedures

#### Escalation Path
1. **Level 1**: Application team attempts basic troubleshooting
2. **Level 2**: Infrastructure team reviews AWS console, CloudWatch
3. **Level 3**: Engage AWS Support (if support plan available)

#### Emergency Access
```bash
# Enable emergency SSH access to webapp (if needed)
# Uncomment SSH rules in modules/security/main.tf
# terraform apply

# Connect to investigate
ssh -i market-practice-key.pem ubuntu@<webapp-ip>

# Check application logs
sudo docker logs webapp-container
```

## Automation Scripts

### Health Check Script
```bash
#!/bin/bash
# health-check.sh

echo "=== Database Health Check ==="
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)

echo "Testing RDS connection..."
mysql -h $RDS_ENDPOINT -u admin -p$DB_PASSWORD -e "SELECT 1" market_db

echo "Testing Redis connection..."
redis-cli -h $REDIS_ENDPOINT ping

echo "Checking CloudWatch metrics..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=market-staging-mysql \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Backup Verification Script
```bash
#!/bin/bash
# verify-backups.sh

echo "=== Backup Verification ==="

echo "Latest RDS snapshots:"
aws rds describe-db-snapshots \
  --db-instance-identifier market-staging-mysql \
  --query 'DBSnapshots[?Status==`available`].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output table

echo "Latest Redis snapshots:"
aws elasticache describe-snapshots \
  --replication-group-id market-staging-redis \
  --query 'Snapshots[?SnapshotStatus==`available`].[SnapshotName,SnapshotCreateTime]' \
  --output table
```

## Best Practices Summary

### 🔐 Security
- Regular password rotation (quarterly)
- Network isolation via VPC and security groups
- Encryption at rest and in transit
- Regular security group audits

### 📊 Monitoring
- Set up CloudWatch alarms for key metrics
- Regular performance reviews
- Automated health checks
- Log aggregation and analysis

### 💾 Backup & Recovery
- Test restore procedures monthly
- Document recovery procedures
- Maintain RTO/RPO objectives
- Cross-region backup strategy for critical data

### 🚀 Performance
- Regular performance tuning
- Capacity planning based on growth trends
- Cache hit ratio monitoring
- Query optimization

### 💰 Cost Optimization
- Right-size instances based on usage
- Use appropriate storage types
- Monitor and optimize backup retention
- Regular cost reviews and optimization

This guide should be reviewed and updated quarterly, and all procedures should be tested in staging before applying to production.