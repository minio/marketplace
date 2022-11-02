### Install `mpdev`

- https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md

### Generate yaml for minio-operator

kustomize build github.com/minio/operator/resources/?ref=v4.5.3 > manifest/minio-operator-4-5-3.yaml