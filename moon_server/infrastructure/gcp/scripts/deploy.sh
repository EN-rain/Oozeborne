#!/bin/bash

# Deployment script for Moon Server
# Usage: ./deploy.sh PROJECT_ID

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh PROJECT_ID"
    exit 1
fi

PROJECT_ID=$1
REGION="asia-southeast1"
REPO_NAME="moon-server"

echo "🚀 Starting deployment to GCP project: $PROJECT_ID"

# 1. Enable APIs
echo "Enabling Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

# 2. Create Artifact Registry Repository if not exists
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository for Moon Server" \
    --project=$PROJECT_ID || echo "Repository already exists"

# 3. Configure Docker to use Artifact Registry
echo "Configuring Docker auth..."
gcloud auth configure-docker $REGION-docker.pkg.dev

# 4. Build and Push Images
SERVICES=("lobby-api" "game-server" "admin-portal")

for SERVICE in "${SERVICES[@]}"; do
    echo "📦 Building and pushing $SERVICE..."
    IMAGE_TAG="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE:latest"
    
    cd ../../../$SERVICE
    docker build -t $IMAGE_TAG .
    docker push $IMAGE_TAG
    cd ../infrastructure/gcp/scripts
done

echo "✅ Images pushed successfully!"
echo "--------------------------------------------------"
echo "Next steps:"
echo "1. SSH into your VM instance."
echo "2. Install Docker Compose if not already present."
echo "3. Update your docker-compose.yml on the VM to use the new images:"
echo "   image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/[service]:latest"
echo "4. Run 'docker-compose up -d'"
