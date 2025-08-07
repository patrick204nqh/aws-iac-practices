import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

/**
 * Properties for KeyPair construct
 */
export interface KeyPairProps {
  /**
   * Name prefix for the key pair
   * @default 'market-practice'
   */
  keyNamePrefix?: string;
  
  /**
   * Output directory for the key file
   * @default './' (current directory)
   */
  outputDir?: string;
}

/**
 * A construct that generates an EC2 key pair for SSH access
 * 
 * This construct will:
 * 1. Generate a unique key name with a random suffix
 * 2. Create a key pair using the CDK EC2 KeyPair construct
 * 3. Output the key name for use with EC2 instances
 * 
 * Note: After deployment, you will need to download the private key using SSM.
 * The construct provides instructions as a stack output.
 */
export class KeyPair extends Construct {
  /**
   * The name of the generated key pair
   */
  public readonly keyName: string;

  /**
   * The path where the key will be saved
   */
  public readonly keyPath: string;

  constructor(scope: Construct, id: string, props: KeyPairProps = {}) {
    super(scope, id);

    // Generate a random suffix for unique key name
    const suffix = crypto.randomBytes(2).toString('hex');
    
    // Set default key name prefix if not provided
    const keyNamePrefix = props.keyNamePrefix || 'market-practice';
    
    // Create unique key name with random suffix
    this.keyName = `${keyNamePrefix}-key-${suffix}`;
    
    // Set key output directory (default to current directory)
    const outputDir = props.outputDir || './';
    this.keyPath = path.join(outputDir, `${this.keyName}.pem`);
    
    // Create the key pair in AWS
    const keyPair = new ec2.CfnKeyPair(this, 'Resource', {
      keyName: this.keyName,
    });
    
    // Add outputs with instructions for retrieving the key
    new cdk.CfnOutput(this, 'KeyName', {
      value: this.keyName,
      description: 'The name of the key pair created for SSH access',
    });
    
    new cdk.CfnOutput(this, 'KeyPairId', {
      value: keyPair.attrKeyPairId,
      description: 'The ID of the key pair for retrieving the private key',
    });
    
    new cdk.CfnOutput(this, 'KeyRetrievalCommand', {
      value: `aws ssm get-parameter --name /ec2/keypair/${keyPair.attrKeyPairId} --with-decryption --query Parameter.Value --output text > ${this.keyPath} && chmod 600 ${this.keyPath}`,
      description: 'Command to retrieve the private key file using AWS CLI',
    });
  }
}