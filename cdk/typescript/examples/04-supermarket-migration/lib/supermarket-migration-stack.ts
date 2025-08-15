import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as elasticache from 'aws-cdk-lib/aws-elasticache';
import * as opensearch from 'aws-cdk-lib/aws-opensearchservice';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class SupermarketMigrationStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // VPC with public and private subnets across 2 AZs
    const vpc = new ec2.Vpc(this, 'SupermarketVpc', {
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      maxAzs: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'PublicSubnet',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'PrivateSubnet',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 24,
          name: 'DatabaseSubnet',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
    });

    // Security Groups
    const albSecurityGroup = new ec2.SecurityGroup(this, 'ALBSecurityGroup', {
      vpc,
      description: 'Security group for Application Load Balancer',
      allowAllOutbound: true,
    });
    albSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'Allow HTTP');
    albSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'Allow HTTPS');

    const ecsSecurityGroup = new ec2.SecurityGroup(this, 'ECSSecurityGroup', {
      vpc,
      description: 'Security group for ECS services',
      allowAllOutbound: true,
    });
    ecsSecurityGroup.addIngressRule(albSecurityGroup, ec2.Port.tcp(80), 'Allow ALB to ECS Flask app');

    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc,
      description: 'Security group for RDS database',
      allowAllOutbound: false,
    });
    dbSecurityGroup.addIngressRule(ecsSecurityGroup, ec2.Port.tcp(3306), 'Allow ECS to MySQL');

    const cacheSecurityGroup = new ec2.SecurityGroup(this, 'CacheSecurityGroup', {
      vpc,
      description: 'Security group for Redis cache',
      allowAllOutbound: false,
    });
    cacheSecurityGroup.addIngressRule(ecsSecurityGroup, ec2.Port.tcp(6379), 'Allow ECS to Redis');

    const searchSecurityGroup = new ec2.SecurityGroup(this, 'SearchSecurityGroup', {
      vpc,
      description: 'Security group for OpenSearch',
      allowAllOutbound: false,
    });
    searchSecurityGroup.addIngressRule(ecsSecurityGroup, ec2.Port.tcp(443), 'Allow ECS to OpenSearch');

    // RDS MySQL Database with Multi-AZ
    const dbSubnetGroup = new rds.SubnetGroup(this, 'DatabaseSubnetGroup', {
      vpc,
      description: 'Subnet group for RDS database',
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
    });

    const database = new rds.DatabaseInstance(this, 'SupermarketDatabase', {
      engine: rds.DatabaseInstanceEngine.mysql({
        version: rds.MysqlEngineVersion.VER_8_0,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE3, ec2.InstanceSize.MICRO),
      vpc,
      subnetGroup: dbSubnetGroup,
      securityGroups: [dbSecurityGroup],
      multiAz: true,
      allocatedStorage: 20,
      storageType: rds.StorageType.GP2,
      backupRetention: cdk.Duration.days(7),
      deletionProtection: false, // Set to true for production
      databaseName: 'supermarket',
      credentials: rds.Credentials.fromGeneratedSecret('admin', {
        secretName: 'supermarket-db-credentials',
      }),
    });

    // ElastiCache Redis Cluster
    const cacheSubnetGroup = new elasticache.CfnSubnetGroup(this, 'CacheSubnetGroup', {
      description: 'Subnet group for Redis cache',
      subnetIds: vpc.selectSubnets({
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      }).subnetIds,
    });

    const redisCache = new elasticache.CfnCacheCluster(this, 'SupermarketCache', {
      cacheNodeType: 'cache.t3.micro',
      engine: 'redis',
      numCacheNodes: 1,
      cacheSubnetGroupName: cacheSubnetGroup.ref,
      vpcSecurityGroupIds: [cacheSecurityGroup.securityGroupId],
    });
    redisCache.addDependency(cacheSubnetGroup);

    // OpenSearch Domain
    const searchDomain = new opensearch.Domain(this, 'SupermarketSearch', {
      version: opensearch.EngineVersion.OPENSEARCH_2_11,
      capacity: {
        dataNodes: 1,
        dataNodeInstanceType: 'm6g.small.search',
      },
      ebs: {
        volumeSize: 20,
        volumeType: ec2.EbsDeviceVolumeType.GP2,
      },
      vpc,
      vpcSubnets: [{
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      }],
      securityGroups: [searchSecurityGroup],
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'SupermarketCluster', {
      vpc,
      containerInsights: true,
    });

    // ECS Task Definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'SupermarketTaskDef', {
      memoryLimitMiB: 512,
      cpu: 256,
    });

    // Add container to task definition
    const container = taskDefinition.addContainer('SupermarketApp', {
      image: ecs.ContainerImage.fromRegistry('ghcr.io/patrick204nqh/simple-webapp:latest'),
      memoryLimitMiB: 512,
      environment: {
        // Flask configuration
        FLASK_ENV: 'production',
        
        // AWS service endpoints for monitoring
        DB_HOST: database.instanceEndpoint.hostname,
        DB_PORT: '3306',
        REDIS_HOST: redisCache.attrRedisEndpointAddress,
        REDIS_PORT: '6379',
        SEARCH_HOST: searchDomain.domainEndpoint,
        SEARCH_PORT: '443',
        
        // Application configuration
        APP_NAME: 'SuperMarket E-commerce Platform',
        ENVIRONMENT: 'aws-production',
        
        // Service monitoring configuration
        SERVICES_CONFIG: JSON.stringify({
          services: [
            {
              name: 'MySQL Database (RDS)',
              host: database.instanceEndpoint.hostname,
              port: 3306,
              type: 'tcp',
              description: 'Primary MySQL database for product catalog, users, and orders'
            },
            {
              name: 'Redis Cache (ElastiCache)', 
              host: redisCache.attrRedisEndpointAddress,
              port: 6379,
              type: 'tcp',
              description: 'Redis cache for session storage and query caching'
            },
            {
              name: 'OpenSearch (Search Engine)',
              host: searchDomain.domainEndpoint,
              port: 443,
              type: 'tcp', 
              description: 'OpenSearch cluster for product search and analytics'
            },
            {
              name: 'Application Health Check',
              host: '127.0.0.1',
              port: 80,
              type: 'tcp',
              description: 'Local Flask application health check'
            }
          ]
        }),
      },
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'supermarket-app',
        logRetention: 7, // 7 days retention
      }),
    });

    container.addPortMappings({
      containerPort: 80,
      protocol: ecs.Protocol.TCP,
    });

    // ECS Service
    const service = new ecs.FargateService(this, 'SupermarketService', {
      cluster,
      taskDefinition,
      desiredCount: 2,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      securityGroups: [ecsSecurityGroup],
    });

    // Application Load Balancer
    const alb = new elbv2.ApplicationLoadBalancer(this, 'SupermarketALB', {
      vpc,
      internetFacing: true,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      securityGroup: albSecurityGroup,
    });

    // ALB Target Group
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'SupermarketTargetGroup', {
      vpc,
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targets: [service],
      healthCheck: {
        path: '/api/instance-info',
        healthyHttpCodes: '200',
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
      },
    });

    // ALB Listener
    alb.addListener('SupermarketListener', {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Outputs
    new cdk.CfnOutput(this, 'LoadBalancerURL', {
      value: `http://${alb.loadBalancerDnsName}`,
      description: 'SuperMarket application URL',
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'RDS database endpoint',
    });
  }
}
