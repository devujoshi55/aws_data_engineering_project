#!/bin/bash
set -euo pipefail

# -------- CONFIG --------
STACK_NAME="aws_resources_provisioned"
TEMPLATE_FILE="../aws_parent_stack.yml"
REGION="us-east-1"

# -------- DEPLOY --------
echo "Deploying CloudFormation stack: $STACK_NAME"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$REGION"

# -------- STATUS --------
if [ $? -eq 0 ]; then
  echo "✅ Stack deployment successful"
else
  echo "❌ Stack deployment failed"
  exit 1
fi
