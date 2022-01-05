# Deploy MinIO through Google Cloud Marketplace

### Prerequisites

- Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts)
- Login to GCP with gcloud `gcloud auth login` 
- Set the default project `gcloud config set project [YOUR-PROJECT-NAME]`

### 1. Create a GKE cluster
Update the REGION and run the following command. For example `us-central1`
```
gcloud container clusters create minio-cluster \
  --region=REGION \
  --num-nodes=4 \
  --machine-type=n2-standard-32 \
  --local-ssd-count=24
```

Configure kubectl
```
gcloud container clusters get-credentials minio-cluster --region=REGION
```

### 2. Install MinIO from Google Cloud Marketplace

- Goto https://console.cloud.google.com/marketplace/product/minio-inc-public/minio-enterpise
- Click `Purchase`
- Select the Cluster created above
- Click `Deploy`

### 3. Access MinIO Operator

Run the following command and copy the token
```
kubectl get secret $(kubectl get serviceaccount console-sa --namespace minio-operator -o jsonpath="{.secrets[0].name}") --namespace minio-operator -o jsonpath="{.data.token}" | base64 --decode
```
```
kubectl port-forward svc/console 9090 -n minio-operator
```
Open http://localhost:9090 and use the token

### 4. Create MinIO tenant

Install local volume provisioner

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/sig-storage-local-static-provisioner/master/helm/generated_examples/gke.yaml
```

Create a new tenant from Operator (http://localhost:9090)

![image](https://user-images.githubusercontent.com/42696688/146743297-bdb4b1b0-47c7-48cd-8120-97c300761f60.png)

Download the credentials

![image](https://user-images.githubusercontent.com/42696688/146743430-c075f272-8a49-46c3-96fa-f32d18af70f1.png)
