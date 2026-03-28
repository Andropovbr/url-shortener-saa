#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-792025037142}"
REPO_NAME="${REPO_NAME:-url-shortener-saa-repository}"
IMAGE_TAG="${IMAGE_TAG:-sha-abc1234}"

IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker build -t "$IMAGE_URI" ./app
docker push "$IMAGE_URI"
