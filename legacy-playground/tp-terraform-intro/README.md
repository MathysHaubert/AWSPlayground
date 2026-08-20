# Exercise — Terraform & MiniStack Introduction: DynamoDB Table for Transactions

**Type:** Setup / hands-on
**Level:** Beginner (first time using Terraform)
**Estimated time:** 30-45 min

## Context

For a fintech service, we want to store transactions in a managed key-value store without managing any server infrastructure. Before deploying anything to a real AWS account (and incurring costs), we want to validate the architecture and application code locally.

**Goal:** provision a DynamoDB table with Terraform against a local AWS emulator (MiniStack), then write a Python script that inserts data into it **idempotently**.

## Constraints

- No real AWS account: everything must run locally via Docker
- Infrastructure defined as code (Terraform), no manual console clicking
- The table must not expose a fixed column schema — only the primary key is declared
- Writing a transaction that already exists (same `transaction_id`) must be **explicitly rejected**, not silently overwritten

## Prerequisites

- Docker installed and running
- Terraform CLI installed
- Python 3 with `boto3` (`pip install boto3 --break-system-packages`)

## Steps

1. **Environment**: start MiniStack via `docker-compose` (port `4566`), check its health via `/_localstack/health`

   ```yaml
   services:
     ministack:
       image: ministackorg/ministack
       ports:
         - "4566:4566"
   ```

2. **Terraform provider**: configure the `hashicorp/aws` provider with dummy credentials and a DynamoDB endpoint redirected to `http://localhost:4566`

3. **Resource**: declare an `aws_dynamodb_table` resource named `Transactions`, `PAY_PER_REQUEST` billing mode, with `transaction_id` (type `S`) as the partition key — no sort key

4. **Terraform cycle**: `terraform init` → `terraform plan` → `terraform apply`, then verify the table was created (AWS CLI, or a resource browser such as StackPort)

5. **Python script (boto3)**:
   - Write an item to the table (`put_item`)
   - Read it back (`get_item`) and observe the returned type (watch out for `Decimal`)
   - Protect the write with `ConditionExpression="attribute_not_exists(transaction_id)"` to prevent duplicates
   - Catch and distinguish the `ConditionalCheckFailedException` from any other `ClientError`

6. **Cleanup**: `terraform destroy`

## Deliverables

- `provider.tf` + `main.tf` (infrastructure)
- `write_transaction.py` (idempotent write script)
- One sentence explaining why `put_item` alone does not guarantee write idempotency

## Points to think through (justify in your write-up)

- Why `PAY_PER_REQUEST` rather than `PROVISIONED` for a local/test workload?
- Why does DynamoDB require no "service provisioning" step before creating a table, unlike a service such as Lambda?
- What actually happens, on the DynamoDB side, when two concurrent writes target the same partition key without a `ConditionExpression`?

## `.gitignore`

```gitignore
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
*.tfplan
crash.log
crash.*.log

# Python
__pycache__/
*.pyc
venv/
.venv/
```

Never commit `*.tfstate` — it stores every resource attribute Terraform manages in plain text, including secrets pulled from the provider (e.g. database passwords, API keys) if such resources are ever added.
