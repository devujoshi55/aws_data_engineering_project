#!/bin/bash
set -euxo pipefail

# -------- CONFIG --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_STACK="aws-bootstrap-stack"
STACK_NAME="aws-resources-provisioned"
BOOTSTRAP_TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_bootstrap_stack.yml"
TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_parent_stack.yml"
REGION="us-east-1"
PACKAGED_TEMPLATE="${SCRIPT_DIR}/packaged.yml"

export AWS_DEFAULT_REGION="$REGION"

echo "Script directory: $SCRIPT_DIR"
echo "Parent template file: $TEMPLATE_FILE"

# -------- CHECK BOOTSTRAP STACK --------
echo "Checking if bootstrap stack exists..."

if aws cloudformation describe-stacks \
    --stack-name "$BOOTSTRAP_STACK" >/dev/null 2>&1; then
  echo "✅ Bootstrap stack already exists. Skipping creation."
else
  echo "🚀 Bootstrap stack not found. Creating..."

  aws cloudformation deploy \
    --stack-name "$BOOTSTRAP_STACK" \
    --template-file "$BOOTSTRAP_TEMPLATE_FILE"
fi

# -------- GET BUCKET NAME --------
BUCKET=$(aws cloudformation describe-stacks \
  --stack-name "$BOOTSTRAP_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='TemplateBucketName'].OutputValue" \
  --output text)

echo "Using bucket: $BUCKET"

# -------- PACKAGE --------
aws cloudformation package \
  --template-file "$TEMPLATE_FILE" \
  --s3-bucket "$BUCKET" \
  --output-template-file "$PACKAGED_TEMPLATE"

# -------- DEPLOY MAIN STACK --------
echo "Deploying main stack: $STACK_NAME"

DEPLOY_STATUS=0
aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$PACKAGED_TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM || DEPLOY_STATUS=$?

# -------- STATUS --------
if [ $DEPLOY_STATUS -eq 0 ]; then
  echo "✅ Stack deployment successful"
else
  echo "❌ Stack deployment failed"
fi

# -------- EVENTS --------
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --query 'StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table

exit $DEPLOY_STATUS
