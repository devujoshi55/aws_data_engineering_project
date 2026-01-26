#!/bin/bash
set -euxo pipefail

# -------- CONFIG --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_STACK="aws-bootstrap-stack"
STACK_NAME="aws-resources-provisioned"

BOOTSTRAP_TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_bootstrap_stack.yml"
TEMPLATE_FILE="${SCRIPT_DIR}/../templates/aws_parent_stack.yml"
PACKAGED_TEMPLATE="${SCRIPT_DIR}/packaged.yml"

REGION="us-east-1"
export AWS_DEFAULT_REGION="$REGION"

echo "Script directory: $SCRIPT_DIR"
echo "Parent template file: $TEMPLATE_FILE"

# -------- DEPLOY BOOTSTRAP STACK --------
aws cloudformation deploy \
  --stack-name "$BOOTSTRAP_STACK" \
  --template-file "$BOOTSTRAP_TEMPLATE_FILE"

# -------- FETCH ARTIFACT BUCKET --------
BUCKET=$(aws cloudformation describe-stacks \
  --stack-name "$BOOTSTRAP_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFormationBucketName'].OutputValue" \
  --output text)

echo "Using artifact bucket: $BUCKET"

# -------- PACKAGE TEMPLATE --------
aws cloudformation package \
  --template-file "$TEMPLATE_FILE" \
  --s3-bucket "$BUCKET" \
  --output-template-file "$PACKAGED_TEMPLATE"

# -------- LINT PACKAGED TEMPLATE --------
echo "Linting packaged CloudFormation template"
cfn-lint "$PACKAGED_TEMPLATE"

#--------UPLOAD SRC CODE -------------------
echo "Uploading Glue ETL scripts to S3..."

aws s3 cp \
  "${SCRIPT_DIR}/../src" \
  "s3://${BUCKET}/etl_src_code/" \
  --recursive

echo "✅ Glue ETL scripts uploaded successfully"


# -------- DEPLOY MAIN STACK --------
echo "Deploying main stack: $STACK_NAME"

DEPLOY_STATUS=0
aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$PACKAGED_TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset || DEPLOY_STATUS=$?

# -------- DEPLOY STATUS --------
if [ $DEPLOY_STATUS -eq 0 ]; then
  echo "✅ Stack deployment successful"
else
  echo "❌ Stack deployment failed"
fi

# -------- STACK EVENTS --------
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --query 'StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table

exit $DEPLOY_STATUS
