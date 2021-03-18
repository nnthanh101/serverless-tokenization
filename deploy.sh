#!/bin/bash

source ./.env.sh
# source ./.cloud9.sh

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
sam deploy --stack-name ${STACK_NAME}                                       \
                     --template-file ./packaged.yaml                              \
                     --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
                     --capabilities CAPABILITY_IAM                                    \
                     --s3-bucket ${S3_BUCKET} --s3-prefix backend \
                     --config-file samconfig.toml                                     \
                     --no-confirm-changeset                                                 \
                     --tags                                                                                     \
                           Project=${PROJECT_ID}

echo "CloudFormation > Describe Stack ${STACK_NAME}"
aws cloudformation describe-stacks --stack-name ${STACK_NAME}

echo
echo "#########################################################"
echo "[+] Step 2. Create Lambda Layer for String Tokenization & Encrypted Data Store"
echo "#########################################################"
echo

export STACK_NAME2=tokenizer
cd ../${STACK_NAME2}

echo "2.1. Run the script to compile and install the dependent libraries in dynamodb-client/python/ directory"
source ./get_AMI_packages_cryptography.sh

echo "2.2. Build the SAM template (template.yaml)"
sam build --use-container 

echo "2.3. Copy the python files ddb_encrypt_item.py and hash_gen.py to dynamodb-client/python/"
cp ddb_encrypt_item.py dynamodb-client/python/
cp hash_gen.py dynamodb-client/python/

echo "2.4. Package the code and push to S3 Bucket."
sam package --s3-bucket ${S3_BUCKET} --output-template-file packaged.yaml

echo "2.5. packaged.yaml will be used to deploy the code and resources to AWS."
sam deploy --stack-name ${STACK_NAME2}                          \
               --template-file ./packaged.yaml                    \
               --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
               --capabilities CAPABILITY_IAM                        \
               --s3-bucket ${S3_BUCKET} --s3-prefix backend \
               --config-file samconfig.toml                         \
               --no-confirm-changeset                                 \
               --tags                                                         \
                    Project=${PROJECT_ID}

echo "CloudFormation > Describe Stack ${STACK_NAME2}"
aws cloudformation describe-stacks --stack-name ${STACK_NAME2}

# echo $(aws cognito-identity list-identity-pools --max-results 10)
# IdentityPoolID=$(aws cognito-identity list-identity-pools --max-results 10 | jq -r '.[] | .[0].IdentityPoolId')
# echo ${IdentityPoolID}

# echo $(aws dynamodbstreams list-streams --table-name ${PROJECT_ID}Questions)
# YourDynamoDBStreamARN=$(aws dynamodbstreams list-streams --table-name ${PROJECT_ID}Questions | jq -r '.[] | .[0].StreamArn')
# echo ${YourDynamoDBStreamARN}

export YourLambdaLayer="arn:aws:lambda:ap-southeast-1:701571471198:layer:TokenizeData:3"
export YourKMSArn="arn:aws:kms:ap-southeast-1:701571471198:key/a73acd1f-f4ff-40c3-b4b2-36c72958f4ef"
export YourDynamoDBArn="arn:aws:dynamodb:ap-southeast-1:701571471198:table/CreditCardTokenizerTable"


echo
echo "#########################################################"
echo "[+] Step 3. Create Serverless Application: API-Gateway, Lambda, Cognito"
echo "#########################################################"
echo

export STACK_NAME3=M2M-App
cd ../${STACK_NAME3}

echo "3.1. Build SAM template. Replace the parameters with previously noted values for LayerVersionArn (Step 2.5.)
sam build --use-container --parameter-overrides layerarn=${YourLambdaLayer}

echo "3.2. Package the code and push to S3 Bucket."
sam package --s3-bucket ${S3_BUCKET} --output-template-file packaged.yaml

echo "3.3. packaged.yaml will be used to deploy the code and resources to AWS."
sam deploy  --stack-name ${STACK_NAME3}                  \
            --template-file ./packaged.yaml              \
            --region ${AWS_REGION} --confirm-changeset --no-fail-on-empty-changeset \
            --capabilities CAPABILITY_IAM                \
            --s3-bucket ${S3_BUCKET} --s3-prefix backend \
            --config-file samconfig.toml                 \
            --no-confirm-changeset                       \
            --parameter-overrides                        \
              layerarn=${YourLambdaLayer}                \
              kmsid=${YourKMSArn}                        \
              dynamodbarn=${YourDynamoDBArn}             \
            --tags                                       \
              Project=${PROJECT_ID}
                  
# echo
# echo "#########################################################"
# echo "[+] Danger!!! Cleanup"
# echo "#########################################################"
# echo

# echo "Cleanup ..."
# export STACK_NAME=KMS-Key
# export STACK_NAME2=tokenizer
# aws cloudformation delete-stack --stack-name ${STACK_NAME}
# aws cloudformation delete-stack --stack-name ${STACK_NAME2}
# sleep 30
# aws s3 rb s3://${S3_BUCKET} --force