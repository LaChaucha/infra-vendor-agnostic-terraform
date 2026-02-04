# infra-vendor-agnostic-terraform

Terraform Infrastructure-as-Code repo designed to be portable across cloud providers via a **facade (contract) layer** and **vendor-specific implementations**.  
This project currently includes a minimal AWS implementation and a LocalStack-based demo for quick, cost-free validation.

---

## Goals

- Keep environment root modules (`envs/*`) **vendor-agnostic** and clean
- Make cloud provider swap a matter of changing the **implementation module**, not rewriting environments
- Provide a **demo-friendly workflow** using LocalStack for the `nonprod` stack
- Model:
  - 2 networks (conceptually): **prod** and **nonprod (dev+qa)**
  - 2 Availability Zones
  - VPN module present (toggleable), but typically disabled for LocalStack demos

---

## Architecture

### Logical diagram (vendor-agnostic)

```text
On-Prem/HQ  <---(S2S VPN, redundant tunnels)--->  Prod VPC (2 AZ)
On-Prem/HQ  <---(S2S VPN, redundant tunnels)--->  NonProd VPC (Dev+QA, 2 AZ)
```

![Architecture Diagram](docs/images/architecture.png)

---

## Repository structure

```text
modules/
  facade/
    network/   # vendor-agnostic contract
    vpn/       # vendor-agnostic contract
  aws/
    network/   # AWS implementation
    vpn/       # AWS implementation
envs/
  prod/        # real AWS target
  nonprod/     # LocalStack demo target (and optional real AWS)
localstack/
  docker-compose.yml
scripts/
  # optional helper scripts
Makefile
```

---

## Prerequisites

### Required
- Docker + Docker Compose
- Terraform CLI
- GNU Make
- AWS CLI (for `local-status-*` targets)

### For LocalStack Terraform convenience (recommended)
- Python 3.x
- `terraform-local` package (provides `tflocal`)
  - Install:
    ```powershell
    py -m pip install --user terraform-local
    ```

> Note: In Windows, `tflocal` may be installed but not visible in your PATH. See Troubleshooting.

---

## Quickstart (LocalStack demo - nonprod)

This demo runs **only `envs/nonprod`** against LocalStack.

1) Start LocalStack
```bash
make local-up
```

2) Apply the nonprod stack to LocalStack
```bash
make local-apply
```

3) Show created resources (filtered by project tags)
```bash
make local-status-all
```

4) Reset the demo (destroy + cleanup)
```bash
make local-clean
```

---

## Quickstart (Real AWS)

> ⚠️ Ensure your AWS credentials are configured in your shell before running these.

Apply prod to AWS:
```bash
make aws-apply-prod
```

Destroy prod:
```bash
make aws-destroy-prod
```

Apply nonprod to AWS:
```bash
make aws-apply-nonprod
```

Destroy nonprod:
```bash
make aws-destroy-nonprod
```

---

## Make targets

Common:
- `make help`
- `make fmt`
- `make validate`

LocalStack:
- `make local-up`
- `make local-apply`
- `make local-apply-only`
- `make local-status`
- `make local-status-subnets`
- `make local-status-rts`
- `make local-status-all`
- `make local-clean`

AWS:
- `make aws-apply-prod`
- `make aws-destroy-prod`
- `make aws-apply-nonprod`
- `make aws-destroy-nonprod`

---

## Demo outputs (examples)

### `make local-apply` (example)
```text
Plan: 10 to add, 0 to change, 0 to destroy.
...
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
nonprod_vpc_id = "vpc-6c76d553d52902324"
nonprod_vpn_tunnels = tolist([])
```

### `make local-status` (example)
```text
------------------------------------------------------
|                    DescribeVpcs                    |
+-------------------+--------------------------------+
|       Cidr        |             VpcId              |
+-------------------+--------------------------------+
|  10.20.0.0/16     |  vpc-6c76d553d52902324         |
||                       Tags                       ||
|+--------------+-----------------------------------+|
||      Key     |               Value               ||
|+--------------+-----------------------------------+|
||  environment |  nonprod                          ||
||  project     |  infra-vendor-agnostic-terraform  ||
||  Name        |  nonprod                          ||
|+--------------+-----------------------------------+|
```

### `make local-status-subnets` (example)
```text
+------------+----------------+----------------+----------------------------+-------------------------+
|     Az     |     Cidr       |     Name       |         SubnetId           |          VpcId          |
+------------+----------------+----------------+----------------------------+-------------------------+
|  us-east-1a|  10.20.30.0/24 |  nonprod-qa-a  |  subnet-6579b31407a0427de  |  vpc-6c76d553d52902324  |
|  us-east-1a|  10.20.10.0/24 |  nonprod-dev-a |  subnet-465cd236e592c83af  |  vpc-6c76d553d52902324  |
|  us-east-1b|  10.20.20.0/24 |  nonprod-dev-b |  subnet-b5d50e166fc25f2ee  |  vpc-6c76d553d52902324  |
|  us-east-1b|  10.20.40.0/24 |  nonprod-qa-b  |  subnet-544efc6f6a86e5047  |  vpc-6c76d553d52902324  |
+------------+----------------+----------------+----------------------------+-------------------------+
```

### `make local-status-rts` (example)
```text
+--------------------+-------------------------+-------------------------+
|        Name        |      RouteTableId       |          VpcId          |
+--------------------+-------------------------+-------------------------+
|  nonprod-private-rt|  rtb-c0e0de5e5c4ecba10  |  vpc-6c76d553d52902324  |
+--------------------+-------------------------+-------------------------+
```

> Optional screenshots to add under `docs/images/`:
- `docs/images/localstack-status-all.png`
- `docs/images/localstack-subnets.png`
- `docs/images/localstack-rts.png`

---

## Troubleshooting (Windows + PowerShell + LocalStack)

This section documents the real-world issues we faced while making `make local-*` targets work reliably on Windows/PowerShell.

### 1) Docker Compose file not found
**Symptom**
```text
open ...\localstack\docker-compose.yml: The system cannot find the path specified.
```

**Cause**
- Running `make` from an unexpected working directory, or the compose file path is incorrect.

**Fix**
- Confirm the file exists at `localstack/docker-compose.yml`.
- Run `make` from the repository root.
- If needed, switch to absolute paths in the Makefile (most robust on Windows).

---

### 2) `tflocal` not recognized (command not found)
**Symptom**
```text
'tflocal' is not recognized as an internal or external command
```

**Cause**
- `terraform-local` is not installed, or the `Scripts` directory is not in PATH.

**Fix**
- Install:
  ```powershell
  py -m pip install --user terraform-local
  ```
- Ensure the user Scripts folder is on PATH. Common location:
  - `%APPDATA%\\Python\\Python311\\Scripts`
- Alternatively, run LocalStack operations via `make` targets (consistent PATH behavior).

---

### 3) `tflocal` works in `make`, but not in PowerShell
**Symptom**
- `make local-apply` works, but running `tflocal` manually fails:
```text
tflocal : The term 'tflocal' is not recognized ...
```

**Cause**
- Your Make process and your PowerShell session may have different PATH values.

**Fix**
- Prefer:
  ```bash
  make local-apply
  make local-apply-only
  ```
- Or add the Python Scripts folder to your PowerShell session PATH:
  ```powershell
  $env:Path += ";$env:APPDATA\\Python\\Python311\\Scripts"
  ```

---

### 4) `local-status` failed due to bash-specific syntax
**Symptom**
```text
'{' is not recognized as an internal or external command
```

**Cause**
- The Make target used bash idioms (`command -v ... || { ... }`) that do not work in PowerShell/cmd.

**Fix**
- Use AWS CLI directly with LocalStack endpoint + region:
  ```bash
  aws --endpoint-url=http://localhost:4566 --region us-east-1 ec2 describe-vpcs
  ```
- Our Make targets were updated to avoid bash-only constructs.

---

### 5) AWS CLI requires a region (even for LocalStack)
**Symptom**
```text
You must specify a region.
```

**Cause**
- AWS CLI requires `--region` (or AWS config), even when pointing to LocalStack.

**Fix**
- Always include `--region us-east-1` in LocalStack CLI commands.

---

### 6) “Extra” VPC showing up in LocalStack output
**Symptom**
- You see a default VPC like `172.31.0.0/16` in addition to your VPC.

**Cause**
- LocalStack may include default/preexisting resources.

**Fix**
- Filter by tags in queries:
  - `--filters "Name=tag:project,Values=infra-vendor-agnostic-terraform"`

---

## Notes on VPN in LocalStack demos

LocalStack is great for VPC/subnets/route tables.  
Site-to-site VPN (IPsec tunnels, BGP, etc.) is typically not demo-stable in emulation.

Recommended approach:
- Keep the VPN module wired in, but disable it in `envs/nonprod/localstack.tfvars`:
  ```hcl
  enable_vpn = false
  ```

This keeps the architecture consistent (facade + implementation), while ensuring the demo remains reliable.
