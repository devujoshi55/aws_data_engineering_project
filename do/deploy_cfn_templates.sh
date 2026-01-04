#!/bin/bash
set -euxo pipefail

# -------- CONFIG --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="aws-resources-provisioned"
TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_parent_stack.yml"
REGION="us-east-1"

echo "Script directory: $SCRIPT_DIR"
echo "Template file: $TEMPLATE_FILE"

# -------- DEPLOY --------
echo "Deploying CloudFormation stack: $STACK_NAME"

DEPLOY_STATUS=0
aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM || DEPLOY_STATUS=$?

# -------- STATUS --------
if [ $DEPLOY_STATUS -eq 0 ]; then
  echo "✅ Stack deployment successful"
else
  echo "❌ Stack deployment failed"
fi

echo "Stack events:"
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query 'StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table

exit $DEPLOY_STATUS
