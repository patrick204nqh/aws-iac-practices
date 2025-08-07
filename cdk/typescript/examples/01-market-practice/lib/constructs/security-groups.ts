import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export interface SecurityGroupsProps {
  prodVpc: ec2.Vpc;
  bastionVpc: ec2.Vpc;
  myIp: string;
  enableVpcPeering: boolean;
}

export class SecurityGroups extends Construct {
  public readonly webappSg: ec2.SecurityGroup;
  public readonly databaseSg: ec2.SecurityGroup;
  public readonly bastionSg: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props: SecurityGroupsProps) {
    super(scope, id);

    this.bastionSg = this.createBastionSecurityGroup(props);
    this.webappSg = this.createWebappSecurityGroup(props);
    this.databaseSg = this.createDatabaseSecurityGroup(props);
  }

  /**
   * Creates the bastion host security group
   */
  private createBastionSecurityGroup(props: SecurityGroupsProps): ec2.SecurityGroup {
    const sg = new ec2.SecurityGroup(this, 'BastionSecurityGroup', {
      vpc: props.bastionVpc,
      description: 'Security group for bastion host',
      securityGroupName: 'market-bastion-sg',
      allowAllOutbound: true,
    });
    
    sg.addIngressRule(
      ec2.Peer.ipv4(props.myIp),
      ec2.Port.tcp(22),
      'SSH from my IP'
    );
    
    return sg;
  }

  /**
   * Creates the web application security group
   */
  private createWebappSecurityGroup(props: SecurityGroupsProps): ec2.SecurityGroup {
    const sg = new ec2.SecurityGroup(this, 'WebappSecurityGroup', {
      vpc: props.prodVpc,
      description: 'Security group for web application server',
      securityGroupName: 'market-webapp-sg',
      allowAllOutbound: true,
    });
    
    sg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'HTTP from anywhere'
    );
    
    sg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(61208),
      'Glances monitoring'
    );
    
    sg.addIngressRule(
      props.enableVpcPeering ? ec2.Peer.ipv4(props.bastionVpc.vpcCidrBlock) : ec2.Peer.ipv4(props.myIp),
      ec2.Port.tcp(22),
      'SSH from bastion or direct'
    );
    
    return sg;
  }

  /**
   * Creates the database security group
   */
  private createDatabaseSecurityGroup(props: SecurityGroupsProps): ec2.SecurityGroup {
    const sg = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: props.prodVpc,
      description: 'Security group for database server',
      securityGroupName: 'market-database-sg',
      allowAllOutbound: true,
    });
    
    // We'll add the webapp security group reference after it's created
    const webappSgRef = this.webappSg;
    
    sg.addIngressRule(
      ec2.Peer.securityGroupId(webappSgRef.securityGroupId),
      ec2.Port.tcp(3306),
      'MySQL from webapp'
    );
    
    sg.addIngressRule(
      ec2.Peer.securityGroupId(webappSgRef.securityGroupId),
      ec2.Port.tcp(6379),
      'Redis from webapp'
    );
    
    sg.addIngressRule(
      props.enableVpcPeering ? ec2.Peer.ipv4(props.bastionVpc.vpcCidrBlock) : ec2.Peer.ipv4(props.myIp),
      ec2.Port.tcp(22),
      'SSH from bastion or direct'
    );
    
    return sg;
  }
}