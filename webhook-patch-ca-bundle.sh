#!/bin/bash
# Original script found at: https://github.com/morvencao/kube-mutating-webhook-tutorial/blob/master/deployment/webhook-patch-ca-bundle.sh

ROOT=$(cd $(dirname $0)/../../; pwd)

set -o errexit
set -o nounset
set -o pipefail

secret_name="pod-identity-webhook"

export CA_BUNDLE=$(kubectl get secret/$secret_name --namespace=kube-system -o jsonpath='{.data.tls\.crt}' | tr -d '\n')

if command -v envsubst >/dev/null 2>&1; then
    envsubst
else
    sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g"
fi