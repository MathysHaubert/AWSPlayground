# Exercise — Decoupling with SQS + Lambda (CLF-C02 revision)

**Type:** Setup / certification revision
**Level:** Beginner-intermediate

## Goal

Build an asynchronous processing pipeline: a payment service drops a transaction message into an SQS queue instead of calling a processor directly, and a Lambda function consumes it. Illustrates why AWS favors decoupled, asynchronous architectures over direct synchronous calls.

## What was built

- 1 SQS queue (`transactions-queue`, `visibility_timeout_seconds = 60`)
- 1 IAM role for the Lambda, with two attached managed policies (logs + SQS access)
- 1 Lambda function (Python) triggered automatically via an event source mapping on the queue
- Manual test: sent a message via CLI, verified processing through CloudWatch Logs

## Key concepts to remember for the exam

### Why decouple with a queue instead of direct HTTP calls
- With direct HTTP, the caller must wait synchronously for a response — if the receiver is down or overloaded, the request fails or times out and the message is lost unless the caller implements its own retry logic.
- With SQS, the producer drops the message and moves on immediately. The queue acts as a **buffer** absorbing traffic spikes, and the message stays in the queue — surviving consumer downtime — until it's successfully processed or expires (retention period, up to 14 days).

### Visibility timeout
- Starts counting the moment a consumer **receives** a message (not when the message enters the queue).
- While it's running, the message is invisible to other consumers, preventing concurrent double-processing.
- If the consumer doesn't call `DeleteMessage` before the timeout expires, the message becomes visible again for a retry — it is **not** deleted or lost.
- Rule of thumb: the visibility timeout should always exceed the maximum expected processing time (AWS often recommends ~6x the Lambda timeout). Too short a timeout risks the same message being picked up and processed twice in parallel.
- SQS guarantees **at-least-once delivery**, never exactly-once (outside FIFO with deduplication) — consumers must be designed to tolerate duplicates, tying back to the idempotency work from the DynamoDB exercise.

### IAM roles: the two layers
- **Trust policy** (`assume_role_policy`): defines **who** can assume the role (e.g. `Service = "lambda.amazonaws.com"`). Uses `sts:AssumeRole`.
- **Permissions policy** (attached via `policy_arn`): defines **what** the role can do once assumed (e.g. write to CloudWatch Logs, read/delete SQS messages).
- Classic exam trap: a role with very permissive permissions still fails if the trust policy doesn't allow the right service to assume it.

### SQS batch delivery
- Lambda receives SQS messages as a batch (`event["Records"]`, up to 10 by default), never a single message directly — the handler must always loop over records.
- Without `ReportBatchItemFailures` configured, a single failing record fails the **entire batch**, and all messages (including successfully processed ones) become visible again for retry — another reason idempotent processing matters.

### Terraform + Lambda code changes
- `source_code_hash = filebase64sha256(...)` is required so Terraform detects changes inside the zipped code. Without it, Terraform only tracks the `filename` string, which doesn't change even if the code inside does — so a code update could silently fail to redeploy.

## Troubleshooting encountered (real debugging practice)

- **Shell line-continuation bug**: splitting a CLI command across multiple lines with `\` introduced a stray character into a JSON string, causing `json.decoder.JSONDecodeError: Extra data`.
- **Typo'd queue name**: sending to `transaction-queue` (no "s") instead of `transactions-queue` succeeded silently — MiniStack auto-creates queues on first use, a permissive behavior not found on real AWS. The message landed in a queue with no Lambda attached, and was never processed. Lesson: always verify exact resource names with `list-queues` rather than assuming.

## Cleanup

```bash
terraform destroy
```
