#!/bin/bash

# patch the self-signed certificate in to mutatingwebhook
cat pod-identity-webhook/mutatingwebhook.yaml | ./webhook-patch-ca-bundle.sh > pod-identity-webhook/mutatingwebhook-ca-bundle.yaml

# deploy the pod identity webhook related k8s resources
echo 'Applying configuration to active cluster...'
kubectl create -f pod-identity-webhook/auth.yaml
kubectl create -f pod-identity-webhook/deployment.yaml
kubectl create -f pod-identity-webhook/service.yaml
kubectl create -f pod-identity-webhook/mutatingwebhook-ca-bundle.yaml

sleep 1

#kubectl certificate approve $(kubectl get csr --namespace=kube-system -o jsonpath='{.items[?(@.spec.username=="system:serviceaccount:default:pod-identity-webhook")].metadata.name}')
