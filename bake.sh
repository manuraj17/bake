#!/bin/bash

# ==============================================================================
#  Script Name: bake.sh
#  Description: This script clones a specified Git repository into a temporary
#               directory, builds a Docker image from the cloned repository, tags
#               the image with a format "<date>.<latest-commit-hash-short>", and
#               pushes the image to a specified AWS ECR repository.
#
#  Usage:       ./clone_build_and_push_image.sh
#
#  Author:      gitub.com/manuraj17
#  Date:        2024-07-11
#  Version:     1.0
#
#  Prerequisites:
#               - AWS CLI configured with appropriate permissions
#               - Docker installed and running
#               - Git installed
#
#  Parameters:
#               - AWS_REGION: The AWS region where the ECR repository is located.
#               - ECR_REPOSITORY_NAME: The name of the ECR repository.
#               - REPOSITORY_URL: The URL of the Git repository to clone.
#
#  Example:
#               AWS_REGION="us-west-2" \
#               ECR_REPOSITORY_NAME="my-ecr-repo" \
#               REPOSITORY_URL="https://github.com/yourusername/yourrepo.git" \
#               ./bake.sh
#
# ==============================================================================

# Variables
AWS_REGION="your-aws-region"                   # e.g., us-west-2
ECR_REPOSITORY_NAME="your-ecr-repository-name" # e.g., my-ecr-repo
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPOSITORY_URL="your-repo-url" # e.g., https://github.com/yourusername/yourrepo.git
IMAGE_NAME="image-name"
TEMP_DIR=$(mktemp -d)

# Clone the repository into a temporary directory
git clone $REPOSITORY_URL "$TEMP_DIR" --depth 1

# Navigate to the temporary directory
cd "$TEMP_DIR" || exit

# Get the current date in the format "YYYYMMDDHHMM"
current_date=$(date +"%Y%m%d%H%M")

# Get the current date in ISO 8601 format for the label
# current_date_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get the latest commit hash and shorten it to 7 characters
commit_hash=$(git rev-parse --short HEAD)

# Combine them to form the tag
tag="$current_date.$commit_hash"

# Build the Docker image with the tag and creation date label
docker build -t "$IMAGE_NAME:$tag" .

# Authenticate Docker to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Tag the Docker image with the ECR repository URI
docker tag "$IMAGE_NAME:$tag" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$tag"

# Push the Docker image to the ECR repository
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$tag"

# Output the image URI
echo "Image pushed: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$tag"

# Clean up the temporary directory
cd ..
rm -rf "$TEMP_DIR"
