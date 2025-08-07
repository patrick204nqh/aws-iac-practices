import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as fs from 'fs';
import * as path from 'path';

export interface InstancesProps {
  prodVpc: ec2.Vpc;
  bastionVpc: ec2.Vpc;
  webappSg: ec2.SecurityGroup;
  databaseSg: ec2.SecurityGroup;
  bastionSg: ec2.SecurityGroup;
  keyName: string;
  webappInstanceType: string;
  databaseInstanceType: string;
  bastionInstanceType: string;
}

export class Instances extends Construct {
  public readonly database: ec2.Instance;
  public readonly webapp: ec2.Instance;
  public readonly bastion: ec2.Instance;

  constructor(scope: Construct, id: string, props: InstancesProps) {
    super(scope, id);

    // Find Ubuntu AMI
    const ubuntu = ec2.MachineImage.lookup({
      name: 'ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*',
      owners: ['099720109477'], // Canonical
    });
    
    // Create instances
    this.database = this.createDatabaseInstance(ubuntu, props);
    this.webapp = this.createWebappInstance(ubuntu, props);
    this.bastion = this.createBastionInstance(ubuntu, props);
  }

  /**
   * Creates the database instance
   */
  private createDatabaseInstance(machineImage: ec2.IMachineImage, props: InstancesProps): ec2.Instance {
    const instance = new ec2.Instance(this, 'DatabaseInstance', {
      vpc: props.prodVpc,
      instanceType: new ec2.InstanceType(props.databaseInstanceType),
      machineImage: machineImage,
      securityGroup: props.databaseSg,
      keyName: props.keyName,
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
    
    // Add user data script
    const userDataPath = path.join(__dirname, '..', '..', 'user-data', 'database.sh');
    instance.addUserData(fs.readFileSync(userDataPath, 'utf8'));
    
    // Add tags
    cdk.Tags.of(instance).add('Name', 'market-database');
    cdk.Tags.of(instance).add('Type', 'database');
    
    return instance;
  }

  /**
   * Creates the web application instance
   */
  private createWebappInstance(machineImage: ec2.IMachineImage, props: InstancesProps): ec2.Instance {
    const instance = new ec2.Instance(this, 'WebappInstance', {
      vpc: props.prodVpc,
      instanceType: new ec2.InstanceType(props.webappInstanceType),
      machineImage: machineImage,
      securityGroup: props.webappSg,
      keyName: props.keyName,
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
    
    // We need to reference database instance properties, so we need to make sure database is created first
    instance.node.addDependency(this.database);

    // Add user data script with variable replacement
    const userDataPath = path.join(__dirname, '..', '..', 'user-data', 'webapp.sh');
    const webappUserData = fs.readFileSync(userDataPath, 'utf8')
      .replace('${database_private_ip}', this.database.instancePrivateIp);
    
    instance.addUserData(webappUserData);
    
    // Add tags
    cdk.Tags.of(instance).add('Name', 'market-webapp');
    cdk.Tags.of(instance).add('Type', 'webapp');
    
    return instance;
  }

  /**
   * Creates the bastion host instance
   */
  private createBastionInstance(machineImage: ec2.IMachineImage, props: InstancesProps): ec2.Instance {
    const instance = new ec2.Instance(this, 'BastionInstance', {
      vpc: props.bastionVpc,
      instanceType: new ec2.InstanceType(props.bastionInstanceType),
      machineImage: machineImage,
      securityGroup: props.bastionSg,
      keyName: props.keyName,
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
    
    // Add dependencies to make sure we can access properties of other instances
    instance.node.addDependency(this.webapp);
    instance.node.addDependency(this.database);
    
    // Add user data script with variable replacement
    const userDataPath = path.join(__dirname, '..', '..', 'user-data', 'bastion.sh');
    const bastionUserData = fs.readFileSync(userDataPath, 'utf8')
      .replace('${webapp_private_ip}', this.webapp.instancePrivateIp)
      .replace('${database_private_ip}', this.database.instancePrivateIp);
    
    instance.addUserData(bastionUserData);
    
    // Add tags
    cdk.Tags.of(instance).add('Name', 'market-bastion');
    cdk.Tags.of(instance).add('Type', 'bastion');
    
    return instance;
  }
}