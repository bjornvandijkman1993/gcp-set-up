# Exit immediately on unhandled error
set -e

IMAGE_NAME=hello-world
TAG=latest
PROJECT_ID=makefile-378011
LOCATION=europe-west4
REPOSITORY=hello-world

# Login and set the project ID
make gcp-initial-set-up
