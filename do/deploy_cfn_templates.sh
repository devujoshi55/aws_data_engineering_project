#!/bin/bash
set -euo pipefail

# -------- CONFIG --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="aws-resources-provisioned"
TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_parent_stack.yml"
REGION="us-east-1"

echo "Script directory: $SCRIPT_DIR"
echo "Template file: $TEMPLATE_FILE"

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
