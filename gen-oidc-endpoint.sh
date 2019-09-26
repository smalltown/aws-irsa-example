#!/bin/bash

rm -rf keys
mkdir -p keys

# Generate the keypair
PRIV_KEY="keys/oidc-issuer.key"
PUB_KEY="keys/oidc-issuer.key.pub"
PKCS_KEY="keys/oidc-issuer.pem"

# Generate a key pair
ssh-keygen -t rsa -b 2048 -f $PRIV_KEY -m pem -N ""

# convert the SSH pubkey to PKCS8
ssh-keygen -e -m PKCS8 -f $PUB_KEY > $PKCS_KEY

# create S3 Bucket
timestamp=$(date +%s)
AWS_DEFAULT_REGION=$(aws configure get region)
S3_BUCKET=aws-irsa-oidc-$timestamp
aws s3api create-bucket --bucket $S3_BUCKET --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION

HOSTNAME=s3-$AWS_DEFAULT_REGION.amazonaws.com
ISSUER_HOSTPATH=$HOSTNAME/$S3_BUCKET

# Create discover.json and keys.json
cat <<EOF > discovery.json
{
    "issuer": "https://$ISSUER_HOSTPATH/",
    "jwks_uri": "https://$ISSUER_HOSTPATH/keys.json",
    "authorization_endpoint": "urn:kubernetes:programmatic_authorization",
    "response_types_supported": [
        "id_token"
    ],
    "subject_types_supported": [
        "public"
    ],
    "id_token_signing_alg_values_supported": [
        "RS256"
    ],
    "claims_supported": [
        "sub",
        "iss"
    ]
}
EOF

go run ./main.go -key $PKCS_KEY  | jq '.keys += [.keys[0]] | .keys[1].kid = ""' > keys.json

# Upload discover.json and keys.json to s3
aws s3 cp --acl public-read ./discovery.json s3://$S3_BUCKET/.well-known/openid-configuration
aws s3 cp --acl public-read ./keys.json s3://$S3_BUCKET/keys.json

# Create OIDC identity provider
CA_THUMBPRINT=$(openssl s_client -connect s3-$AWS_DEFAULT_REGION.amazonaws.com:443 -servername s3-$AWS_DEFAULT_REGION.amazonaws.com -showcerts < /dev/null 2>/dev/null  |  openssl x509 -in /dev/stdin -sha1 -noout -fingerprint | cut -d '=' -f 2 | tr -d ':')

aws iam create-open-id-connect-provider \
     --url https://$ISSUER_HOSTPATH \
     --thumbprint-list $CA_THUMBPRINT \
     --client-id-list sts.amazonaws.com

echo "The service-account-issuer as below:"
echo "https://$ISSUER_HOSTPATH"