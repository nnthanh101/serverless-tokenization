#!/bin/bash

source ./.env.sh

export STACK_NAME=KMS-Key
export STACK_NAME2=tokenizer
export STACK_NAME3=M2M-App

echo "[+] Step 1. Create KMS - Customer Managed Keys"
aws cloudformation describe-stacks --stack-name ${STACK_NAME}
echo "==YourKMSArn arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT}:key/___"
YourKMSArn=$(aws kms list-aliases | jq -r '.[] | .[0].AliasArn')
echo ${YourKMSArn}

echo "[+] Step 2. Create Lambda Layer for String Tokenization & Encrypted Data Store"
aws cloudformation describe-stacks --stack-name ${STACK_NAME2}
echo "===YourLayervErsionArn arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT}:layer:TokenizeData:___"
YourLayervErsionArn=$(aws cloudformation list-exports | jq -r '.[] | .[0].Value')
echo ${YourLayervErsionArn}

echo "===YourDynamoDBArn arn:aws:dynamodb:${AWS_REGION}:${AWS_ACCOUNT}:table/CreditCardTokenizerTable"
export YourDynamoDBArn="arn:aws:dynamodb:${AWS_REGION}:${AWS_ACCOUNT}:table/CreditCardTokenizerTable"
echo ${YourDynamoDBArn}

echo "[+] Step 3. Create Serverless Application: API-Gateway, Lambda, Cognito"
aws cloudformation describe-stacks --stack-name ${STACK_NAME3}
echo "3.4. CloudFormation > Describe Stack ${STACK_NAME3}"              
aws cloudformation describe-stacks --stack-name ${STACK_NAME3} --region ${AWS_REGION}

echo "===YourUserPoolAppClientId: Cognito >> General settings >> App client id"
export YourUserPools=$(aws cognito-idp list-user-pools --max-results 10 | jq -r '.[] | .[0].Id')
export YourUserPoolAppClientId=$(aws cognito-idp list-user-pool-clients --user-pool-id $YourUserPools | jq -r '.[] | .[0].ClientId')
echo ${YourUserPoolAppClientId}

export ROOTPrincipal="arn:aws:iam::${AWS_ACCOUNT}:root"

echo "===YourLambdaExecutionRole arn:aws:iam::${AWS_ACCOUNT}:role/M2M-App-LambdaExecutionRole___"
YourLambdaExecutionRole=`aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${STACK_NAME3}  | \
                         jq -r '.Stacks[].Outputs[] | select(.OutputKey == "LambdaExecutionRole") | .OutputValue'`
echo ${YourLambdaExecutionRole}

echo "===YourPaymentMethodApiURL https://___.execute-api.${AWS_REGION}.amazonaws.com/dev"
YourPaymentMethodApiURL=`aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${STACK_NAME3}  | \
                         jq -r '.Stacks[].Outputs[] | select(.OutputKey == "PaymentMethodApiURL") | .OutputValue'`
echo ${YourPaymentMethodApiURL} 

## FIXME
POLICY=$(cat << EOF
{ 
    "Version": "2012-10-17", 
    "Id": "kms-cmk-1", 
    "Statement": [ 
        { 
            "Sid": "Enable IAM User Permissions", 
            "Effect": "Allow", 
            "Principal": {"AWS": ["$ROOTPrincipal"]}, 
            "Action": "kms:*", 
            "Resource": "$YourKMSArn" 
        }, 
        { 
            "Sid": "Enable IAM User Permissions", 
            "Effect": "Allow", 
            "Principal": {"AWS": ["$YourLambdaExecutionRole"]}, 
            "Action": ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:GenerateDataKeyWithoutPlaintext"], 
            "Resource": "$YourKMSArn" 
        } 
    ] 
}
EOF
); \
aws kms put-key-policy --key-id "${YourKMSArn}" --policy-name default --policy "$POLICY"

## FIXME 2

aws cognito-idp sign-up --region ${AWS_REGION} --client-id $YourUserPoolAppClientId --username nnthanh101@gmail.com --password Passw0rd!

echo "Note: Cognito Confirm Email"
aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --client-id $YourUserPoolAppClientId --auth-parameters USERNAME=nnthanh101@gmail.com,PASSWORD=Passw0rd!

curl -X POST \
 $YourPaymentMethodApiURL/order     \
-H 'Authorization: $YourIdToken'    \
-H 'Content-Type: application/json' \
-d '{
"CustomerOrder": "123456789",
"CustomerName": "Amazon Web Services",
"CreditCard": "0000-0000-0000-0000",
"Address": "Unicorn Gym - APJ 2021"
}'

curl -X POST \
 $YourPaymentMethodApiURL/paybill \
-H 'Authorization: $YourIdToken' \
-H 'Content-Type: application/json' \
-d '{
"CustomerOrder": "123456789"
}'

## Reference FYI ONLY

# YOUR_COGNITO_REGION=ap-southeast-2
# YOUR_COGNITO_APP_CLIENT_ID=1mmmmubo6107id5fj5t6bpvvjl
# YOUR_EMAIL=nnthanh101@gmail.com
# YOUR_PASSWORD=@unicorn-gym-m2m

# echo "Sign up new cognito User"
# echo aws cognito-idp sign-up \--region $YOUR_COGNITO_REGION \--client-id $YOUR_COGNITO_APP_CLIENT_ID \--username $YOUR_EMAIL \--password $YOUR_PASSWORD

# echo "Verify User"
# echo aws cognito-idp confirm-sign-up \--client-id $YOUR_COGNITO_APP_CLIENT_ID \--username $YOUR_EMAIL \--confirmation-code CONFIRMATION_CODE_IN_EMAIL

# echo "Get Id Token"
# echo aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --client-id $YOUR_COGNITO_APP_CLIENT_ID --auth-parameters USERNAME=$YOUR_EMAIL,PASSWORD=$YOUR_PASSWORD
