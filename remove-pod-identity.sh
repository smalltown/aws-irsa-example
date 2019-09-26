#!/bin/bash

# patch the self-signed certificate in to mutatingwebhook
cat pod-identity-webhook/mutatingwebhook.yaml | ./webhook-patch-ca-bundle.sh > pod-identity-webhook/mutatingwebhook-ca-bundle.yaml

# deploy the pod identity webhook related k8s resources
echo 'Delete configuration fron active cluster...'
kubectl delete -f pod-identity-webhook/auth.yaml
kubectl delete -f pod-identity-webhook/deployment.yaml
kubectl delete -f pod-identity-webhook/service.yaml
kubectl delete -f pod-identity-webhook/mutatingwebhook-ca-bundle.yaml

