#!/usr/bin/env bash
set -euo pipefail

# Start LocalStack (idempotent)
docker compose -f localstack/docker-compose.yml up -d

# Apply only NONPROD using LocalStack profile vars
(
  cd "envs/nonprod"
  tflocal init
  tflocal apply -auto-approve -var-file=localstack.tfvars
)

echo "OK. Check resources with:"
echo "  awslocal ec2 describe-vpcs"