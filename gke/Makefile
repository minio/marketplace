REGISTRY ?= gcr.io/minio-inc-public
TAG ?= 4.5.4
RELEASE_TAG ?= 4.5
MARKETPLACE_TOOLS_TAG ?= 0.11.5

$(info ---- TAG = $(TAG))

DEPLOYER_IMAGE ?= $(REGISTRY)/minio/deployer:$(TAG)
DEPLOYER_IMAGE_RELEASE ?= $(REGISTRY)/minio/deployer:$(RELEASE_TAG)

TESTER_IMAGE ?= $(REGISTRY)/minio/tester:$(TAG)
TESTER_IMAGE_RELEASE ?= $(REGISTRY)/minio/tester:$(RELEASE_TAG)

MINIO_IMAGE_SRC = minio/minio:RELEASE.2022-11-17T23-20-09Z
MINIO_IMAGE = $(REGISTRY)/minio:$(TAG)
MINIO_IMAGE_RELEASE = $(REGISTRY)/minio:$(RELEASE_TAG)

# OPERATOR_IMAGE_SRC = minio/operator:v4.4.6
# OPERATOR_IMAGE = $(REGISTRY)/minio/operator:$(TAG)
# OPERATOR_IMAGE_RELEASE = $(REGISTRY)/minio/operator:$(RELEASE_TAG)

CONSOLE_IMAGE_SRC = minio/console:v0.21.1
CONSOLE_IMAGE = $(REGISTRY)/minio/console:$(TAG)
CONSOLE_IMAGE_RELEASE = $(REGISTRY)/minio/console:$(RELEASE_TAG)

UBB_AGENT_IMAGE_SRC = gcr.io/cloud-marketplace-tools/metering/ubbagent:0.1.1
UBB_AGENT_IMAGE =  $(REGISTRY)/minio/ubbagent:$(TAG)
UBB_AGENT_IMAGE_RELEASE =  $(REGISTRY)/minio/ubbagent:$(RELEASE_TAG)

build/deployer:
	docker build \
		--build-arg REGISTRY="$(REGISTRY)/minio" \
		--build-arg TAG="$(TAG)" \
		--build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
		--tag "$(DEPLOYER_IMAGE)" \
		-f deployer/Dockerfile \
		.

	docker push "$(DEPLOYER_IMAGE)"
	docker tag "$(DEPLOYER_IMAGE)" "$(DEPLOYER_IMAGE_RELEASE)"
	docker push "$(DEPLOYER_IMAGE_RELEASE)"

build/tester:
	$(call print_target,$@)
	cd apptest/tester \
		&& docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	docker tag "$(TESTER_IMAGE)" "$(TESTER_IMAGE_RELEASE)"
	docker push "$(TESTER_IMAGE_RELEASE)"

deployer/verify:
	mpdev verify --deployer="$(DEPLOYER_IMAGE)"

deployer/install:
	kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml
	kubectl create namespace minio-operator || echo true
	mpdev install --deployer="$(DEPLOYER_IMAGE)" \
	       --parameters='{"name": "operator-deployment", "namespace": "minio-operator", "reportingSecret": "minio-enterprise-license" }'

images:
	docker pull "$(MINIO_IMAGE_SRC)"
	docker tag "$(MINIO_IMAGE_SRC)" "$(MINIO_IMAGE)"
	docker push "$(MINIO_IMAGE)" 
	docker tag "$(MINIO_IMAGE)" "$(MINIO_IMAGE_RELEASE)"
	docker push "$(MINIO_IMAGE_RELEASE)"

# docker pull "$(OPERATOR_IMAGE_SRC)"
# docker tag "$(OPERATOR_IMAGE_SRC)" "$(OPERATOR_IMAGE)"
# docker push "$(OPERATOR_IMAGE)"
# docker tag "$(OPERATOR_IMAGE)" "$(OPERATOR_IMAGE_RELEASE)"
# docker push "$(OPERATOR_IMAGE_RELEASE)"

	docker pull "$(CONSOLE_IMAGE_SRC)"
	docker tag "$(CONSOLE_IMAGE_SRC)" "$(CONSOLE_IMAGE)"
	docker push "$(CONSOLE_IMAGE)"
	docker tag "$(CONSOLE_IMAGE)" "$(CONSOLE_IMAGE_RELEASE)"
	docker push "$(CONSOLE_IMAGE_RELEASE)"

	docker pull "$(UBB_AGENT_IMAGE_SRC)"
	docker tag "$(UBB_AGENT_IMAGE_SRC)" "$(UBB_AGENT_IMAGE)"
	docker push "$(UBB_AGENT_IMAGE)"
	docker tag "$(UBB_AGENT_IMAGE)" "$(UBB_AGENT_IMAGE_RELEASE)"
	docker push "$(UBB_AGENT_IMAGE_RELEASE)"
