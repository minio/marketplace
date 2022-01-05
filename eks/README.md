# Setting up MinIO on AWS EKS

The following steps will guide you through setting up MinIO on AWS EKS

## Pre-requisites


> ⚠️ **You must create a subcription in the AWS Marketplace for MinIO else the automation from this setup won't work due to a missing entitlement.**


Additionally:

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

## 2.- Setup required Roles, Policies and Connectors

All of these are scoped to the specific cluster called `Cluster Name` on `region` on the given `account number`, so make
sure to update those values

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
    --attach-policy-arn arn:aws:iam::<AWS_ACCOUNT_NUMBER>:policy/minio-eks-minio-cluster-group-scaling \
    --approve \
    --override-existing-serviceaccounts
```

## 3.- Install Operator

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

### 4.1 - Open the UI and create a Tenant

Go to http://localhost:9090 enter the JWT from the previous step and create a tenant.


## 5.- Sign Up for MinIO Subscription Network

To receive support send us an email to subnet@min.io to get started and receive 24/7 support 
