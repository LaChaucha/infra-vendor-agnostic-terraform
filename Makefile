SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# Ensure Python --user Scripts is on PATH (so "tflocal" and "awslocal" work)
PY_USER_BASE := $(shell py -c "import site; print(site.getuserbase())")
PY_USER_BASE := $(subst \,/,$(PY_USER_BASE))
export PATH := $(PY_USER_BASE)/Python311/Scripts:$(PATH)

# Tools (override if needed: make TF=terraform1.6 ...)
TF       ?= terraform
TFLOCAL  ?= tflocal
DC       ?= docker compose -f localstack/docker-compose.yml

# Var files
AWS_PROD_VARS     ?= terraform.tfvars
AWS_NONPROD_VARS  ?= terraform.tfvars
LOCAL_NONPROD_VARS?= localstack.tfvars

# Defaults
AUTO_APPROVE ?= -auto-approve

.PHONY: help
help:
	@echo "Targets:"
	@echo "  local-up               Start LocalStack"
	@echo "  local-down             Stop LocalStack"
	@echo "  local-logs             Tail LocalStack logs"
	@echo "  local-apply            Apply NONPROD to LocalStack (uses envs/nonprod/$(LOCAL_NONPROD_VARS))"
	@echo "  local-destroy          Destroy NONPROD from LocalStack"
	@echo "  local-status           List VPCs in LocalStack (requires awslocal)"
	@echo ""
	@echo "  aws-apply-prod          Apply PROD to real AWS (uses envs/prod/$(AWS_PROD_VARS))"
	@echo "  aws-destroy-prod        Destroy PROD from real AWS"
	@echo "  aws-apply-nonprod       Apply NONPROD to real AWS (uses envs/nonprod/$(AWS_NONPROD_VARS))"
	@echo "  aws-destroy-nonprod     Destroy NONPROD from real AWS"
	@echo ""
	@echo "  fmt                    terraform fmt -recursive"
	@echo "  validate               terraform validate (prod + nonprod)"
	@echo ""
	@echo "Examples:"
	@echo "  make local-up && make local-apply"
	@echo "  make aws-apply-prod"
	@echo "  make aws-destroy-nonprod"

# -------------------------
# LocalStack
# -------------------------
.PHONY: local-up
local-up:
	$(DC) up -d

.PHONY: local-down
local-down:
	$(DC) down

.PHONY: local-logs
local-logs:
	$(DC) logs -f --tail=200

.PHONY: local-apply
local-apply: local-up
	cd envs/nonprod
	$(TFLOCAL) init
	$(TFLOCAL) apply $(AUTO_APPROVE) -var-file=$(LOCAL_NONPROD_VARS)

.PHONY: local-destroy
local-destroy: local-up
	cd envs/nonprod
	$(TFLOCAL) init
	$(TFLOCAL) destroy $(AUTO_APPROVE) -var-file=$(LOCAL_NONPROD_VARS)

.PHONY: local-clean
local-clean: local-up
	# 1) Destroy NONPROD resources in LocalStack (ignore if nothing exists)
	cd envs/nonprod
	-$(TFLOCAL) init
	-$(TFLOCAL) destroy $(AUTO_APPROVE) -var-file=$(LOCAL_NONPROD_VARS)

	# 2) Remove local terraform artifacts/state for the demo env
	-rm -rf .terraform .terraform.lock.hcl
	-rm -f terraform.tfstate terraform.tfstate.backup

	# 3) Optional: wipe LocalStack persisted data (full reset)
	cd ../../localstack
	-rm -rf .localstack

	@echo "LocalStack NONPROD demo reset complete."

LOCALSTACK_ENDPOINT ?= http://localhost:4566
LOCAL_AWS_REGION    ?= us-east-1
.PHONY: local-status
local-status:
	aws --endpoint-url=$(LOCALSTACK_ENDPOINT) --region $(LOCAL_AWS_REGION) ec2 describe-vpcs --query "Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,Tags:Tags}" --output table

.PHONY: local-apply-only
local-apply-only: local-up
	cd envs/nonprod
	$(TFLOCAL) apply $(AUTO_APPROVE) -var-file=$(LOCAL_NONPROD_VARS)

.PHONY: local-status-subnets
local-status-subnets:
	aws --endpoint-url=$(LOCALSTACK_ENDPOINT) --region $(LOCAL_AWS_REGION) ec2 describe-subnets \
	  --filters "Name=tag:project,Values=infra-vendor-agnostic-terraform" \
	  --query "Subnets[].{SubnetId:SubnetId,VpcId:VpcId,Cidr:CidrBlock,Az:AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" \
	  --output table

.PHONY: local-status-rts
local-status-rts:
	aws --endpoint-url=$(LOCALSTACK_ENDPOINT) --region $(LOCAL_AWS_REGION) ec2 describe-route-tables \
	  --filters "Name=tag:project,Values=infra-vendor-agnostic-terraform" \
	  --query "RouteTables[].{RouteTableId:RouteTableId,VpcId:VpcId,Name:Tags[?Key=='Name']|[0].Value}" \
	  --output table

.PHONY: local-status-all
local-status-all: local-status local-status-subnets local-status-rts

# -------------------------
# AWS (real)
# -------------------------
.PHONY: aws-apply-prod
aws-apply-prod:
	cd envs/prod
	$(TF) init
	$(TF) apply $(AUTO_APPROVE) -var-file=$(AWS_PROD_VARS)

.PHONY: aws-destroy-prod
aws-destroy-prod:
	cd envs/prod
	$(TF) init
	$(TF) destroy $(AUTO_APPROVE) -var-file=$(AWS_PROD_VARS)

.PHONY: aws-apply-nonprod
aws-apply-nonprod:
	cd envs/nonprod
	$(TF) init
	$(TF) apply $(AUTO_APPROVE) -var-file=$(AWS_NONPROD_VARS)

.PHONY: aws-destroy-nonprod
aws-destroy-nonprod:
	cd envs/nonprod
	$(TF) init
	$(TF) destroy $(AUTO_APPROVE) -var-file=$(AWS_NONPROD_VARS)

# -------------------------
# Quality
# -------------------------
.PHONY: fmt
fmt:
	$(TF) fmt -recursive

.PHONY: validate
validate:
	cd envs/prod
	$(TF) init -backend=false
	$(TF) validate
	cd ../../envs/nonprod
	$(TF) init -backend=false
	$(TF) validate
