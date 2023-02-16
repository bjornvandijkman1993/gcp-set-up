.PHONY: gcp-initial-set-up gcp-login gcp-set-project enable-artifact-registry authenticate-to-registry create-repository build-and-push-image

IMAGE_NAME=fastapi
TAG=latest
PROJECT_ID=makefile-378011
LOCATION=europe-west4
REPOSITORY=hello-world
PROJECT_NUMBER=248178295773

########### GCP ###########
authenticate-to-registry:
	gcloud auth configure-docker europe-west4-docker.pkg.dev

########### Docker ###########
build-and-push-image:
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker tag $(IMAGE_NAME):$(TAG) $(LOCATION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/$(IMAGE_NAME):$(TAG)
	docker push $(LOCATION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/$(IMAGE_NAME):$(TAG)
