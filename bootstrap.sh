# Exit immediately on unhandled error
set -e

PROJECT_ID=makefile-378011
IMAGE_NAME=fastapi
LOCATION=europe-west4
WIF_POOL=new-github-wif-pool-3
SERVICE_ACCOUNT_NAME=cicd-wif-new

echo "Authenticating to GCP and setting project"
gcloud auth login
gcloud config set project "${PROJECT_ID}"

PROJECT_NUMBER=$(gcloud projects list \
    --filter="$(gcloud config get-value project)" \
    --format="value(PROJECT_NUMBER)")

echo "Enabling required services"
gcloud services enable \
    artifactregistry.googleapis.com \
    iamcredentials.googleapis.com \
    run.googleapis.com \
    cloudscheduler.googleapis.com \
    workflows.googleapis.com

BUCKET_ALREADY_EXISTS=$(gsutil ls | grep ${PROJECT_ID} | { grep -v grep || true; })

if [ -z "${BUCKET_ALREADY_EXISTS}" ]; then
    echo "Creating Terraform state bucket"

    gsutil mb -c standard -l  "${LOCATION}" -p "${PROJECT_ID}" --pap enforced gs://"${PROJECT_ID}"
    # Enable bucket versioning for backup
    gsutil versioning set on gs://"${PROJECT_ID}"
    # Enable lifecycle rule to prevent ever increasing costs
    LC_FILE_NAME=.state_bucket_lifecycle_rule.json
    echo '{"rule": [{"action": {"type": "Delete"}, "condition": {"numNewerVersions": 3}}]}' > $LC_FILE_NAME
    gsutil lifecycle set $LC_FILE_NAME gs://"${PROJECT_ID}"
    rm $LC_FILE_NAME
    echo "$(tput setaf 2)Created Terraform state storage bucket $(tput setaf 7)"
else
    echo "A bucket already exists for Terraform State"
fi


echo "Setting up the workload identity pool"
gcloud iam workload-identity-pools create \
    "${WIF_POOL}" --location="global" --project "${PROJECT_ID}"

gcloud iam workload-identity-pools providers create-oidc github-wif \
    --location="global" --workload-identity-pool="${WIF_POOL}"  \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="attribute.actor=assertion.actor,google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --project "${PROJECT_ID}"

gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
    --display-name="Service account used by WIF POC" \
    --project "${PROJECT_ID}"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT_NAME}@"${PROJECT_ID}".iam.gserviceaccount.com \
    --project="${PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL}/*"