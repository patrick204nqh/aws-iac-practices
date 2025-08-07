import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export interface OutputsProps {
  webapp: ec2.Instance;
  database: ec2.Instance;
  bastion: ec2.Instance;
  keyPath: string;
}

export class Outputs extends Construct {
  constructor(scope: Construct, id: string, props: OutputsProps) {
    super(scope, id);
    
    this.defineOutputs(props);
  }

  /**
   * Define stack outputs
   */
  private defineOutputs(props: OutputsProps): void {
    // Instance IP outputs
    new cdk.CfnOutput(this, 'WebappPublicIP', {
      description: 'Webapp Public IP Address',
      value: props.webapp.instancePublicIp
    });
    
    new cdk.CfnOutput(this, 'WebappPrivateIP', {
      description: 'Webapp Private IP Address',
      value: props.webapp.instancePrivateIp
    });
    
    new cdk.CfnOutput(this, 'DatabasePrivateIP', {
      description: 'Database Private IP Address',
      value: props.database.instancePrivateIp
    });
    
    new cdk.CfnOutput(this, 'BastionPublicIP', {
      description: 'Bastion Public IP Address',
      value: props.bastion.instancePublicIp
    });
    
    // SSH access outputs
    new cdk.CfnOutput(this, 'BastionSSHCommand', {
      description: 'Command to SSH into bastion',
      value: `ssh -i ${props.keyPath} ubuntu@${props.bastion.instancePublicIp}`
    });
    
    new cdk.CfnOutput(this, 'WebappSSHCommand', {
      description: 'Command to SSH into webapp via bastion',
      value: `ssh -i ${props.keyPath} -o ProxyCommand="ssh -i ${props.keyPath} -W %h:%p ubuntu@${props.bastion.instancePublicIp}" ubuntu@${props.webapp.instancePrivateIp}`
    });
    
    new cdk.CfnOutput(this, 'DatabaseSSHCommand', {
      description: 'Command to SSH into database via bastion',
      value: `ssh -i ${props.keyPath} -o ProxyCommand="ssh -i ${props.keyPath} -W %h:%p ubuntu@${props.bastion.instancePublicIp}" ubuntu@${props.database.instancePrivateIp}`
    });
    
    // Application access outputs
    new cdk.CfnOutput(this, 'WebappURL', {
      description: 'URL to access the webapp',
      value: `http://${props.webapp.instancePublicIp}`
    });
    
    new cdk.CfnOutput(this, 'GlancesURL', {
      description: 'URL to access Glances monitoring',
      value: `http://${props.webapp.instancePublicIp}:61208`
    });
  }
}