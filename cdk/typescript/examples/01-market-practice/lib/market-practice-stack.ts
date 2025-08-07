import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { KeyPair } from './constructs/key-pair';
import { Network } from './constructs/network';
import { SecurityGroups } from './constructs/security-groups';
import { Instances } from './constructs/instances';
import { Outputs } from './constructs/outputs';

/**
 * Stack for the Market Practice infrastructure
 */
export class MarketPracticeStack extends cdk.Stack {
  // Context parameters
  private readonly myIp: string;
  private readonly enableVpcPeering: boolean;
  private readonly webappInstanceType: string;
  private readonly databaseInstanceType: string;
  private readonly bastionInstanceType: string;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Get context values
    this.myIp = this.node.tryGetContext('my_ip') || '0.0.0.0/32';
    this.enableVpcPeering = this.node.tryGetContext('enable_vpc_peering') !== false;
    this.webappInstanceType = this.node.tryGetContext('webapp_instance_type') || 't3.micro';
    this.databaseInstanceType = this.node.tryGetContext('database_instance_type') || 't3.micro';
    this.bastionInstanceType = this.node.tryGetContext('bastion_instance_type') || 't3.micro';

    // Create key pair
    const keyPair = new KeyPair(this, 'KeyPair', {
      keyNamePrefix: 'market-practice',
      outputDir: './'
    });

    // Create network infrastructure
    const network = new Network(this, 'Network', {
      enableVpcPeering: this.enableVpcPeering
    });

    // Create security groups
    const securityGroups = new SecurityGroups(this, 'SecurityGroups', {
      prodVpc: network.prodVpc,
      bastionVpc: network.bastionVpc,
      myIp: this.myIp,
      enableVpcPeering: this.enableVpcPeering
    });

    // Create instances
    const instances = new Instances(this, 'Instances', {
      prodVpc: network.prodVpc,
      bastionVpc: network.bastionVpc,
      webappSg: securityGroups.webappSg,
      databaseSg: securityGroups.databaseSg,
      bastionSg: securityGroups.bastionSg,
      keyName: keyPair.keyName,
      webappInstanceType: this.webappInstanceType,
      databaseInstanceType: this.databaseInstanceType,
      bastionInstanceType: this.bastionInstanceType
    });

    // Define outputs
    new Outputs(this, 'Outputs', {
      webapp: instances.webapp,
      database: instances.database,
      bastion: instances.bastion,
      keyPath: keyPair.keyPath
    });
  }
}