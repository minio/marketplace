# Upstream Minio on EKS

> **_NOTE:_**  This guide is a quickstart, the set of minimal steps to install minio upstream on EKS, covers only some of the many aspects to setup a MinIO Cluster and is meant to be a quick install guide for a proof of Concept or evaluation setup.

Prerrequisites:
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
* [eksctl](https://eksctl.io/introduction/#installation) as well an AWS Account and grants to create resources
* [helm](https://helm.sh/docs/intro/install/)
* MinIO Client [mc](https://min.io/docs/minio/linux/reference/minio-mc.html#install-mc)


## Create a EKS cluster using eksctl and config file
First, let's create an AWS EKS cluster [using a config file for the eksctl CLI](https://eksctl.io/usage/creating-and-managing-clusters/#using-config-files). Using eksctl is one of the quickest and simplest ways to create an EKS cluster.

The example config file [cluster.yaml](cluster.yaml) defines a cluster named `example-eks-cluster` under their own VPC, in the `us-east-1` region a single node group `ng-1` with 4 instances of type `m4.xlarge`.
Additionally, creates the IAM Policies in the Instance profile to support [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) and [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/), that we will needing later.


Feel free to modify the [cluster.yaml](cluster.yaml) file to adjust it to your own needs, see the [eksctl documentation](https://eksctl.io/introduction/) for guidance.


_Create the cluser with the config file_

```sh
eksctl create cluster -f cluster.yaml
```


_Install the EBS CSI Driver as a EKS add-on_

```sh
eksctl create addon --name aws-ebs-csi-driver --cluster example-eks-cluster --force
```

_Load Balancer controller, installed with helm_



```sh
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=example-eks-cluster
```

_Optional: Update kubeconfig context_

Usually eksctl would register the cluster and context automatically, however there is cases when the cluster creation fails or timeouts that might miss this step and needs to be executed manually.
```sh
aws eks update-kubeconfig --name example-eks-cluster
```


## Install Upstream minio Operator

Look on [Operator installation instructions](https://github.com/minio/operator#1-install-the-minio-operator) for a detailed step-by-step.

Upstream Operator can be installed on many ways, here are some listed:
* Via kustomization
* Via krew minio plugin
* Via helm charts


### Install via kubectl kustomization

This commands will get the latest version of minio-operator and apply the kustomization

```sh
MINIO_VERSION=$(curl -s "https://api.github.com/repos/minio/operator/releases/latest"|grep '"tag_name":'|sed -E 's/.*"([^"]+)".*/\1/')
kubectl create namespace minio-operator
kubectl apply -k github.com/minio/operator/\?ref\=$MINIO_VERSION -n minio-operator
```

### Installat via krew minio plugin


```sh
kubectl krew update
kubectl krew install minio
kubectl minio init
```

### Install via helm chart


```sh
helm repo add minio-operator https://operator.min.io/
helm install minio-operator --namespace minio-operator --create-namespace minio-operator/operator
```

## Access Operator

### Get Operator Credentials

Once Operator is installed let's get the JWT Credentials to log into it.

_Get JTW stored in the console-sa-secret Secret_
```sh
kubectl get secret -n minio-operator console-sa-secret -o jsonpath={.data.token} | base64 --decode
➜ eyJhbGciOiJSUzI1NiIsImtpZCI6ImZ2aXQ2MlQ3a1NlTjJXOGp3elNxLUxBZ1NseE5TdVozexampletoken...
```

### Proxy Operator Console UI in local env machine

```sh
kubectl minio proxy -n minio-operator

➜ Starting port forward of the Console UI.

➜ To connect open a browser and go to http://localhost:9090

➜ Current JWT to login: eyJhbGciOiJSUzI1NiIsImtpZCI6ImZ2aXQ2MlQ3a1NlTjJXOGp3elNxLUxBZ1NseE5TdVozWjJMRk1yQmMxY2MifQ.eyJhbGciOiJSUzI1NiIsImtpZCI6ImZ2aXQ2MlQ3a1NlTjJXOGp3elNxLUxBZ1NseE5TdVozexampletoken...

➜ Forwarding from 0.0.0.0:9090 -> 9090
```

### Expose Operator Console UI with a Load balancer

In [*WIP MinIO on EKS:  Exposing MinIO services using Elastic Load Balancers*](#)  is explained the different options on how to expose the MinIO Services, for simplicity we are going to follow the Application Load Balancer Ingress approach.

To expose Operator in a Application Load Balancer and assigna a DNS to it let's create a Ingress resource, in this repo is the [../alb/operator-ingress.yaml](../alb/operator-ingress.yaml) example Ingress Manifest, modify it to have your own settings, like:

* Set ALB Subnets to associate to ALB (`alb.ingress.kubernetes.io/subnets` annotation)
* Set AWS ACM Certificate if SSL Termination is desired (`alb.ingress.kubernetes.io/certificate-arn` annotation)
* `alb.ingress.kubernetes.io/scheme` annotation: `internet-facing` to make public the ALB internet reachable, or `internal` so that the ALB is only accessible from the VPC.
* If you chosen to make SSL termination in the ALB, then consider uncomment the `ssl-redirect` to forward any http traffic to the https listener.
* Replace the "operator.exampledomain.com" domain with the actual DNS on wich you want the operator to be accessible.

_apply the Ingress_
```sh
kubect apply -f operator-ingress.yaml
➜ ingress.networking.k8s.io/operator-ingress created
```
Don't forget to assign the DNS to the ALB. If you manage the domain in AWS Route 53 it allows to set an [alias record to the Application Load Balancer](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html).


## Create a MinIO tenant

At this point, we would like to create Tenats, for that we could deploy tenants in many ways, to list some:

* Via Operator UI
* Via tenant Manifest, [See Tenant CRD](https://github.com/minio/operator/blob/master/docs/crd.adoc)
* Via minio krew plugin `kubectl create tenant` command line
* Via Helm Chart

### Create tenant in Operator UI

### Create tenant using a Tenant Manifest

In this repo folder see the example [tenant.yaml](tenant.yaml). It is a Tenant Manifest, see all available fields in the [Tenant CRD](https://github.com/minio/operator/blob/master/docs/crd.adoc)


_Create the tenant_
```sh
kubectl apply -f tenant.yaml
```

### Create tenant using krew plugin

```sh

TENANT_NAME=minio-tenant-1
TENANT_NAMESPACE=minio-tenant-1

kubectl minio tenant create $TENANT_NAME            \
		--servers                 4                 \
		--volumes                 4                 \
		--capacity                1Ti               \
		--storage-class           gp2               \
		--namespace               $TENANT_NAMESPACE \
```

### Create tenant helm chart

This command crates a tenant, with the [default values](https://github.com/minio/operator/blob/master/helm/tenant/values.yaml),
You could specify the values in a yaml file and pass it as a parameter `-f values.yaml`.

```sh
helm repo add minio-operator https://operator.min.io/
helm install minio-tenant-1 --namespace minio-tenant-1 --create-namespace minio-operator/tenant
```


### Expose the tenant MinIO API and Console

In [*WIP MinIO on EKS:  Exposing MinIO services using Elastic Load Balancers*](#) is explained the different options on how to expose the MinIO Services, for simplicity we are going to follow the Application Load Balancer Ingress approach.

To expose The tenant in a Application Load Balancer and assigna a DNS to it let's create a Ingress resource, in this repo is the [../alb/tenant-ingress.yaml](../alb/tenant-ingress.yaml) example Ingress Manifest, modify it to have your own settings, like:

* Set ALB Subnets to associate to ALB (`alb.ingress.kubernetes.io/subnets` annotation)
* Set AWS ACM Certificate if SSL Termination is desired (`alb.ingress.kubernetes.io/certificate-arn` annotation)
* `alb.ingress.kubernetes.io/scheme` annotation: `internet-facing` to make public the ALB internet reachable, or `internal` so that the ALB is only accessible from the VPC.
* If you chosen to make SSL termination in the ALB, then consider uncomment the `ssl-redirect` to forward any http traffic to the https listener.
* Replace the "console.minio-tenant-1.exampledomain.com" and "minio-tenant-1.exampledomain.com" domains with the actual DNS domains on which you want the MinIO API and Console to be accessible.

_apply the Ingress_
```sh
kubect apply -f tenant-ingress.yaml
➜ ingress.networking.k8s.io/tenant-ingress created
```
Don't forget to assign the DNS to the ALB. If you manage the domain in AWS Route 53 it allows to set an [alias record to the Application Load Balancer](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html).

In the example [tenant-ingress.yaml](../alb/tenant-ingress.yaml), the ALB routes both the Console and the API based on the value of the `HOST` header to the proper Kubernetes service, make sure that the both DNS's console and API are pointing to the same ALB.

## Acces MinIO

Test the connection using mc ([detailed guide here](https://min.io/docs/minio/linux/reference/minio-mc.html#test-the-connection))

```sh
mc alias set minioeks https://minio-tenant-1.exampledomain.com ACCESS_KEY SECRET KEY
mc admin info minioeks
```

At this point, you should be able to reach the MinIO API using mc, minio SDK's, AWS CLI, AWS SDK, or even the raw REST API.