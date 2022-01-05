## 0.- Decide on Configuration

You are going to need three basic configuration parameters for your cluster

### 0.1.- Account Number

Your account number can be obtained from the AWS Console or by running the following command

```shell
export AWS_ACCOUNT_NUMBER=`aws sts get-caller-identity --query "Account" --output text` 
echo $AWS_ACCOUNT_NUMBER
```

### 0.2.- Region

Decide a region for example `us-west-2` (dropdown)

### 0.3.- Name the cluster

Pick a name for the cluster, for example `minio-cluster`

## 1.- Setup cluster

```shell
eksctl create cluster --config-file minio-cluster.yaml
```

## 2.- Install Operator (with integration)

```shell
kubectl apply -k github.com/minio/operator/resources/\?ref\=v4.3.7 
```

> ⚠️ Note:️ The install link for the integration will be different

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

## 3.- Get the JWT to login to Operator UI

```shell
kubectl -n minio-operator  get secret $(kubectl -n minio-operator get serviceaccount console-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode 
```

## 4.- Port Forward into Operator UI

```shell
kubectl -n minio-operator port-forward svc/console 9090
```

Go to http://localhost:9090
