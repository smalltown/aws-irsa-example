#!/bin/bash

ISSUER_URL=$1

# create iam role for s3 echoer job
ISSUER_HOSTPATH=$(echo $ISSUER_URL | cut -f 3- -d'/')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROVIDER_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/$ISSUER_HOSTPATH"

cat > irp-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${ISSUER_HOSTPATH}:sub": "system:serviceaccount:default:my-serviceaccount"
        }
      }
    }
  ]
}
EOF

ROLE_NAME=s3-echoer

aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://irp-trust-policy.json

aws iam update-assume-role-policy \
        --role-name $ROLE_NAME \
        --policy-document file://irp-trust-policy.json

aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# create service account for s3 echoer job and attach the iam role
S3_ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query Role.Arn --output text)

kubectl create sa s3-echoer
kubectl annotate sa s3-echoer eks.amazonaws.com/role-arn=$S3_ROLE_ARN

# deploy s3 echoer job into k8s cluster
timestamp=$(date +%s)
TARGET_BUCKET=irp-test-$timestamp

aws s3api create-bucket \
            --bucket $TARGET_BUCKET \
            --create-bucket-configuration LocationConstraint=$(aws configure get region) \
            --region $(aws configure get region)

sed -e "s/TARGET_BUCKET/${TARGET_BUCKET}/g" s3-echoer-job/s3-echoer-job.yaml.template > s3-echoer-job/s3-echoer-job.yaml

kubectl create -f s3-echoer-job/s3-echoer-job.yaml

echo "The Demo S3 bucket as below:"
echo $TARGET_BUCKET