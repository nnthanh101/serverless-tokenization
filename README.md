# Tokenization and Encryption of Sensitive Data

Data Masking solution that ingests data and identifies PII/PCI data and returns masked data back to reduce the exposure of sensitive information, using Serverless Tokenization, SAM and Lambda Layers.

Please refer to [Building a **serverless tokenization solution** to **mask sensitive data**](https://aws.amazon.com/blogs/compute/building-a-serverless-tokenization-solution-to-mask-sensitive-data/), for more info.
 
## Architecture

![Architecture](README/architecture.png)
 
## Prerequisites 
 
1. [ ] [AWS Account](https://aws.amazon.com/free)
2. [ ] [AWS Cloud9-IDE](https://docs.aws.amazon.com/cloud9/latest/user-guide/tutorial-create-environment.html) for writing, running and debugging code on the cloud: `./cloud9.sh`

```
git clone https://github.com/nnthanh101/serverless-tokenization
cd serverless-tokenization

./deploy.sh
```
