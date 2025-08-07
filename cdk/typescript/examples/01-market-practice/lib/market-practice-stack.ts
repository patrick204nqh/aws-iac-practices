import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as fs from 'fs';
import * as path from 'path';

export class MarketPracticeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Context values
    const myIp = this.node.tryGetContext('my_ip') || '0.0.0.0/32';
    const enableVpcPeering = this.node.tryGetContext('enable_vpc_peering') !== false;
    const webappInstanceType = this.node.tryGetContext('webapp_instance_type') || 't3.micro';
    const databaseInstanceType = this.node.tryGetContext('database_instance_type') || 't3.micro';
    const bastionInstanceType = this.node.tryGetContext('bastion_instance_type') || 't3.micro';
    const keyName = this.node.tryGetContext('key_name') || 'market-practice-key';
    
    // Get availability zones
    const availabilityZones = cdk.Stack.of(this).availabilityZones;
    
    // Create Production VPC
    const prodVpc = new ec2.Vpc(this, 'MarketProdVpc', {
      vpcName: 'market-prod',
      maxAzs: 1,
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        }
      ],
      natGateways: 1,
    });
    
    // Create Bastion VPC
    const bastionVpc = new ec2.Vpc(this, 'MarketBastionVpc', {
      vpcName: 'market-bastion',
      maxAzs: 1,
      ipAddresses: ec2.IpAddresses.cidr('192.168.0.0/16'),
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ],
      natGateways: 0,
    });
    
    // Create VPC Peering if enabled
    if (enableVpcPeering) {
      const vpcPeering = new ec2.CfnVPCPeeringConnection(this, 'VpcPeering', {
        vpcId: bastionVpc.vpcId,
        peerVpcId: prodVpc.vpcId,
        tags: [
          { key: 'Name', value: 'market-peering' }
        ]
      });
      
      // Create routes for VPC Peering
      // From Bastion VPC to Production VPC
      bastionVpc.publicSubnets.forEach((subnet, i) => {
        new ec2.CfnRoute(this, `BastionToProdRoute${i}`, {
          routeTableId: subnet.routeTable.routeTableId,
          destinationCidrBlock: prodVpc.vpcCidrBlock,
          vpcPeeringConnectionId: vpcPeering.ref
        });
      });
      
      // From Production VPC to Bastion VPC
      prodVpc.publicSubnets.forEach((subnet, i) => {
        new ec2.CfnRoute(this, `ProdPublicToBastionRoute${i}`, {
          routeTableId: subnet.routeTable.routeTableId,
          destinationCidrBlock: bastionVpc.vpcCidrBlock,
          vpcPeeringConnectionId: vpcPeering.ref
        });
      });
      
      prodVpc.privateSubnets.forEach((subnet, i) => {
        new ec2.CfnRoute(this, `ProdPrivateToBastionRoute${i}`, {
          routeTableId: subnet.routeTable.routeTableId,
          destinationCidrBlock: bastionVpc.vpcCidrBlock,
          vpcPeeringConnectionId: vpcPeering.ref
        });
      });
    }
    
    // Security Groups
    // Bastion Security Group
    const bastionSg = new ec2.SecurityGroup(this, 'BastionSecurityGroup', {
      vpc: bastionVpc,
      description: 'Security group for bastion host',
      securityGroupName: 'market-bastion-sg',
      allowAllOutbound: true,
    });
    
    bastionSg.addIngressRule(
      ec2.Peer.ipv4(myIp),
      ec2.Port.tcp(22),
      'SSH from my IP'
    );
    
    // Webapp Security Group
    const webappSg = new ec2.SecurityGroup(this, 'WebappSecurityGroup', {
      vpc: prodVpc,
      description: 'Security group for web application server',
      securityGroupName: 'market-webapp-sg',
      allowAllOutbound: true,
    });
    
    webappSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'HTTP from anywhere'
    );
    
    webappSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(61208),
      'Glances monitoring'
    );
    
    webappSg.addIngressRule(
      enableVpcPeering ? ec2.Peer.ipv4(bastionVpc.vpcCidrBlock) : ec2.Peer.ipv4(myIp),
      ec2.Port.tcp(22),
      'SSH from bastion'
    );
    
    // Database Security Group
    const databaseSg = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: prodVpc,
      description: 'Security group for database server',
      securityGroupName: 'market-database-sg',
      allowAllOutbound: true,
    });
    
    databaseSg.addIngressRule(
      ec2.Peer.securityGroupId(webappSg.securityGroupId),
      ec2.Port.tcp(3306),
      'MySQL from webapp'
    );
    
    databaseSg.addIngressRule(
      ec2.Peer.securityGroupId(webappSg.securityGroupId),
      ec2.Port.tcp(6379),
      'Redis from webapp'
    );
    
    databaseSg.addIngressRule(
      enableVpcPeering ? ec2.Peer.ipv4(bastionVpc.vpcCidrBlock) : ec2.Peer.ipv4(myIp),
      ec2.Port.tcp(22),
      'SSH from bastion'
    );
    
    // EC2 Instances
    // Find Ubuntu AMI
    const ubuntu = ec2.MachineImage.lookup({
      name: 'ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*',
      owners: ['099720109477'], // Canonical
    });
    
    // Database Instance
    const database = new ec2.Instance(this, 'DatabaseInstance', {
      vpc: prodVpc,
      instanceType: new ec2.InstanceType(databaseInstanceType),
      machineImage: ubuntu,
      securityGroup: databaseSg,
      keyName: keyName,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
      },
      blockDevices: [
        {
          deviceName: '/dev/sda1',
          volume: ec2.BlockDeviceVolume.ebs(8, {
            encrypted: true,
            volumeType: ec2.EbsDeviceVolumeType.GP3,
          }),
        }
      ]
    });
    
    database.addUserData(fs.readFileSync(path.join(__dirname, '..', 'user-data', 'database.sh'), 'utf8'));
    
    // Add Name tag
    cdk.Tags.of(database).add('Name', 'market-database');
    cdk.Tags.of(database).add('Type', 'database');
    
    // Webapp Instance
    const webapp = new ec2.Instance(this, 'WebappInstance', {
      vpc: prodVpc,
      instanceType: new ec2.InstanceType(webappInstanceType),
      machineImage: ubuntu,
      securityGroup: webappSg,
      keyName: keyName,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC
      },
      blockDevices: [
        {
          deviceName: '/dev/sda1',
          volume: ec2.BlockDeviceVolume.ebs(8, {
            encrypted: true,
            volumeType: ec2.EbsDeviceVolumeType.GP3,
          }),
        }
      ]
    });
    
    const webappUserData = fs.readFileSync(path.join(__dirname, '..', 'user-data', 'webapp.sh'), 'utf8')
      .replace('${database_private_ip}', database.instancePrivateIp);
    
    webapp.addUserData(webappUserData);
    
    // Add Name tag
    cdk.Tags.of(webapp).add('Name', 'market-webapp');
    cdk.Tags.of(webapp).add('Type', 'webapp');
    
    // Bastion Instance
    const bastion = new ec2.Instance(this, 'BastionInstance', {
      vpc: bastionVpc,
      instanceType: new ec2.InstanceType(bastionInstanceType),
      machineImage: ubuntu,
      securityGroup: bastionSg,
      keyName: keyName,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC
      },
      blockDevices: [
        {
          deviceName: '/dev/sda1',
          volume: ec2.BlockDeviceVolume.ebs(8, {
            encrypted: true,
            volumeType: ec2.EbsDeviceVolumeType.GP3,
          }),
        }
      ]
    });
    
    const bastionUserData = fs.readFileSync(path.join(__dirname, '..', 'user-data', 'bastion.sh'), 'utf8')
      .replace('${webapp_private_ip}', webapp.instancePrivateIp)
      .replace('${database_private_ip}', database.instancePrivateIp);
    
    bastion.addUserData(bastionUserData);
    
    // Add Name tag
    cdk.Tags.of(bastion).add('Name', 'market-bastion');
    cdk.Tags.of(bastion).add('Type', 'bastion');
    
    // Outputs
    new cdk.CfnOutput(this, 'WebappPublicIP', {
      description: 'Webapp Public IP Address',
      value: webapp.instancePublicIp
    });
    
    new cdk.CfnOutput(this, 'WebappPrivateIP', {
      description: 'Webapp Private IP Address',
      value: webapp.instancePrivateIp
    });
    
    new cdk.CfnOutput(this, 'DatabasePrivateIP', {
      description: 'Database Private IP Address',
      value: database.instancePrivateIp
    });
    
    new cdk.CfnOutput(this, 'BastionPublicIP', {
      description: 'Bastion Public IP Address',
      value: bastion.instancePublicIp
    });
    
    new cdk.CfnOutput(this, 'SSHCommand', {
      description: 'Command to SSH into bastion',
      value: `ssh -i ${keyName}.pem ubuntu@${bastion.instancePublicIp}`
    });
  }
}