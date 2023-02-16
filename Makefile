.PHONY: gcp-initial-set-up gcp-login gcp-set-project enable-artifact-registry authenticate-to-registry create-repository build-and-push-image

IMAGE_NAME=hello-world
TAG=latest
PROJECT_ID=makefile-378011
LOCATION=europe-west4
REPOSITORY=hello-world
PROJECT_NUMBER=248178295773

########### Create artifact registry ###########

gcp-initial-set-up: gcp-login gcp-set-project enable-artifact-registry authenticate-to-registry create-repository

gcp-login:
	gcloud auth login

gcp-set-project:
	gcloud config set project $(PROJECT_ID)

enable-artifact-registry:
	gcloud services enable artifactregistry.googleapis.com

authenticate-to-registry:
	gcloud auth configure-docker europe-west4-docker.pkg.dev

create-repository: 
	gcloud artifacts repositories create $(IMAGE_NAME) \
		--repository-format=docker \
		--location=europe-west4 \
		--description="Hello World"

########### Docker ###########
build-and-push-image:
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker tag $(IMAGE_NAME):$(TAG) $(LOCATION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/$(IMAGE_NAME):$(TAG)
	docker push $(LOCATION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/$(IMAGE_NAME):$(TAG)

########### Workload Identity ###########
create-pool: 
	gcloud iam workload-identity-pools create \
		github-wif-pool --location="global" --project $(PROJECT_ID)

create-provider:
	gcloud iam workload-identity-pools providers create-oidc githubwif \
		--location="global" --workload-identity-pool="github-wif-pool"  \
		--issuer-uri="https://token.actions.githubusercontent.com" \
		--attribute-mapping="attribute.actor=assertion.actor,google.subject=assertion.sub,attribute.repository=assertion.repository" \
		--project $(PROJECT_ID)

create-service-account:
	# gcloud iam service-accounts create test-wif \
	# 	--display-name="Service account used by WIF POC" \
	# 	--project $(PROJECT_ID)

	gcloud projects add-iam-policy-binding $(PROJECT_ID) \
		--member='serviceAccount:test-wif@$(PROJECT_ID).iam.gserviceaccount.com' \
		--role="roles/owner"

bind-service-account:
	gcloud iam service-accounts add-iam-policy-binding test-wif@$(PROJECT_ID).iam.gserviceaccount.com \
		--project=$(PROJECT_ID) \
		--role="roles/iam.workloadIdentityUser" \
		--member="principalSet://iam.googleapis.com/projects/$(PROJECT_NUMBER)/locations/global/workloadIdentityPools/github-wif-pool/*"