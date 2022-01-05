# Setting up MinIO on AWS EKS

The following steps will guide you through setting up MinIO on AWS EKS

## Pre-requisites

* [awscli](https://aws.amazon.com/cli/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [eksctl](https://eksctl.io/introduction/#installation)

## 0.- Before you start

You are going to need three basic configuration parameters for your cluster

`Account Number` can be obtained from the AWS Console or by running the following command

```shell
export AWS_ACCOUNT_NUMBER=`aws sts get-caller-identity --query "Account" --output text` 
echo $AWS_ACCOUNT_NUMBER
```

Decide a `region` for example `us-west-2`

Pick a `Cluster Name`, for example `minio-cluster`

## 1.- Setup cluster

```shell
eksctl create cluster --config-file minio-cluster.yaml
```

## 2.- Install Operator (with integration)

```shell
kubectl apply -k github.com/miniohq/marketplace/eks/resources 
```

### 2.1 Create IAM Policy

```shell
aws iam create-policy \
  --policy-name minio-eks-minio-cluster-group-scaling \
  --policy-document file://iam-policy.json
```

### 2.3 Create a OIDC Provider

```shell
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=minio-cluster --approve
```

### 2.2 Create Trust + Role + Service Account

```shell
eksctl create iamserviceaccount \
    --name minio-operator \
    --namespace minio-operator \
    --cluster minio-cluster \
    --attach-policy-arn arn:aws:iam::804065449417:policy/minio-eks-minio-cluster-group-scaling \
    --approve \
    --override-existing-serviceaccounts
```

## 3.- Install Operator (with integration)

```shell
kubectl apply -k github.com/miniohq/marketplace/eks/resources 
```

### 3.1- Get the JWT to login to Operator UI

```shell
kubectl -n minio-operator  get secret $(kubectl -n minio-operator get serviceaccount console-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode 
```

## 4.- Port Forward into Operator UI

```shell
kubectl -n minio-operator port-forward svc/console 9090
```

Go to http://localhost:9090
