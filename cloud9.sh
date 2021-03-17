#!/bin/bash

## echo "This script support Amazon Linux 2 ONLY !!!"

echo "Installing Utilities: jq, wget, unzip ..."
sudo yum -y update
sudo yum -y upgrade
sudo yum install -y jq wget unzip bash-completion gettext moreutils

echo "Uninstall the AWS CLI version 1 using pip"
sudo pip uninstall awscli
echo "Install the AWS CLI version 2 using pip"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

sudo pip3 install boto3

echo "[x] Verify git":     $(git  --version)
echo "[x] Verify nano":    $(nano --version)
echo "[x] Verify jq":      $(jq   --version)

echo "[x] Verify AWS CLI": $(aws  --version)
# echo "[x] Verify Docker":  $(docker version)
# echo "[x] Verify CDK":     $(cdk  --version)
# echo "[x] Verify Python":  $(python -V)
# echo "[x] Verify Pip":     $(pip -V)
echo "[x] Verify Python3": $(python3 -V)
echo "[x] Verify Pip3":    $(pip3 -V)
