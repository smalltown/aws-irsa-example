module aws-irsa-example

go 1.13

require (
	github.com/aws/amazon-eks-pod-identity-webhook v0.0.0-20190920185843-52363cb3215a
	github.com/pkg/errors v0.8.0
	github.com/prometheus/client_golang v1.1.0
	github.com/spf13/pflag v1.0.5
	gopkg.in/square/go-jose.v2 v2.3.1
	k8s.io/client-go v11.0.1-0.20190606204521-b8faab9c5193+incompatible
	k8s.io/klog v1.0.0
)
