#!/bin/bash

source ./.env.sh

echo "Creating the S3 bucket: ${S3_BUCKET}"
aws s3api create-bucket --bucket ${S3_BUCKET} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION} || true
aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled

echo
echo "#########################################################"
echo "[+] Step 1. Create KMS - Customer Managed Keys"
echo "#########################################################"
echo

export STACK_NAME=KMS-Key
cd ${STACK_NAME}

echo "1.1. Build the SAM template template.yaml"
sam build --use-container

echo "1.2. Package the code and push to S3 Bucket."
sam package --s3-bucket ${S3_BUCKET} --output-template-file packaged.yaml

echo "1.3. packaged.yaml will be used to deploy the code and resources to AWS."
sam deploy --stack-name ${STACK_NAME}                   \
           --template-file ./packaged.yaml              \
           --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
           --capabilities CAPABILITY_IAM                \
           --s3-bucket ${S3_BUCKET} --s3-prefix backend \
           --config-file samconfig.toml                 \
           --no-confirm-changeset                       \
           --tags                                       \
              Project=${PROJECT_ID}

## Danger!!! Cleanup
# echo "Cleanup ..."
# aws cloudformation delete-stack --stack-name ${STACK_NAME}
