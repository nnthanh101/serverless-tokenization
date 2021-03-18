# Tokenization and Encryption of Sensitive Data

Data Masking solution that ingests data and identifies PII/PCI data and returns masked data back to reduce the exposure of sensitive information, using Serverless Tokenization, SAM and Lambda Layers.

Please refer to [Building a **serverless tokenization solution** to **mask sensitive data**](https://aws.amazon.com/blogs/compute/building-a-serverless-tokenization-solution-to-mask-sensitive-data/), for more info.
 
## Architecture

![Architecture](README/architecture.png)

* [x] Serverless Tokenization
* [ ] [Maskopy Solution to Copy and Obfuscate Production Data to Target Environments in AWS](https://github.com/FINRAOS/maskopy)
 
## Prerequisites 
 
1. [ ] [AWS Account](https://aws.amazon.com/free)
2. [ ] [AWS Cloud9-IDE](https://docs.aws.amazon.com/cloud9/latest/user-guide/tutorial-create-environment.html) for writing, running and debugging code on the cloud: `./cloud9.sh`

```
git clone https://github.com/nnthanh101/serverless-tokenization
cd serverless-tokenization

./deploy.sh
```

## Step 1: Create Customer Managed KMS Key `KMS-Key`

* [x] 1.1. Build the SAM template (template.yaml)
  `sam build --use-container`
* [x] 1.2. Package the code and push to S3 Bucket. 
  `sam package --s3-bucket ${S3_BUCKET} --output-template-file packaged.yaml`
* [x] 1.3. Packaged.yaml (created in the above step) will be used to deploy the code and resources to AWS. 
  `sam deploy --template-file ./packaged.yaml --stack-name kms-stack --capabilities CAPABILITY_IAM`
* [x] Get the output variables of the stack 
  `aws cloudformation describe-stacks --stack-name ${STACK_NAME}`

Once done, the output will look like

```json
"Outputs": [
                {
                    "Description": "ARN for KMS-CMK Key created", 
                    "OutputKey": "KMSKeyID", 
                    "OutputValue": "*********"
                }
            ]
```

Note the *OutputValue* of  *OutputKey* `KMSKeyID` from the output for later steps.

The CloudFormation stack created Customer Managed KMS key and gave permissions to the root user to access the key. This master encryption key will be used to generate data encryption keys for encrypting items later in the module. 

## Step 2. Create Lambda Layer for String Tokenization and Encrypted Data Store

```
export SAM_PROJECT=tokenizer

sam init                  \
    --name ${SAM_PROJECT} \
    --package-type Zip    \
    --runtime python3.7   \
    --app-template hello-world 
```