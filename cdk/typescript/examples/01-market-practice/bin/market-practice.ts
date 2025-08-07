#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { MarketPracticeStack } from '../lib/market-practice-stack';

const app = new cdk.App();

// Get context values or use defaults
const env = { 
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: app.node.tryGetContext('aws_region') || 'us-east-1'
};

new MarketPracticeStack(app, 'MarketPracticeStack', {
  env,
  description: 'Market Practice Infrastructure (uksb-1q9p78gcl)',
  tags: {
    Project: 'market-practice',
    Environment: 'practice',
    ManagedBy: 'cdk'
  }
});