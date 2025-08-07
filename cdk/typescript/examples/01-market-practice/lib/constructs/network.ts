import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export interface NetworkProps {
  enableVpcPeering: boolean;
}

export class Network extends Construct {
  public readonly prodVpc: ec2.Vpc;
  public readonly bastionVpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: NetworkProps) {
    super(scope, id);

    // Create Production VPC
    this.prodVpc = this.createProductionVpc();
    
    // Create Bastion VPC
    this.bastionVpc = this.createBastionVpc();
    
    // Set up VPC Peering if enabled
    if (props.enableVpcPeering) {
      this.setupVpcPeering(this.bastionVpc, this.prodVpc);
    }
  }

  /**
   * Creates the Production VPC
   */
  private createProductionVpc(): ec2.Vpc {
    return new ec2.Vpc(this, 'MarketProdVpc', {
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
  }

  /**
   * Creates the Bastion VPC
   */
  private createBastionVpc(): ec2.Vpc {
    return new ec2.Vpc(this, 'MarketBastionVpc', {
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
  }

  /**
   * Sets up VPC peering between the bastion and production VPCs
   */
  private setupVpcPeering(bastionVpc: ec2.Vpc, prodVpc: ec2.Vpc): void {
    // Create VPC peering connection
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
}