
# Exercise — Cost Allocation Tags & CloudWatch Alarms (CLF-C02 revision)

**Type:** Setup / certification revision
**Level:** Beginner-intermediate
**Ties to:** AWS Well-Architected Framework — Operational Excellence & Cost Optimization pillars

## Goal

Add cost allocation tags to an existing Lambda function, then create a CloudWatch alarm to detect repeated failures — connecting two Well-Architected pillars to concrete, previously-built infrastructure (the SQS + Lambda pipeline).

## What was built

- Tags added to the `transaction-processor` Lambda (`Project`, `Environment`, `CostCenter`)
- A `aws_cloudwatch_metric_alarm` watching the Lambda's `Errors` metric (`period = 60`, `evaluation_periods = 1`, `threshold = 0`)
- A deliberately failing version of the Lambda code, deployed to trigger the alarm

## Key concepts to remember for the exam

### Cost allocation tags
- Without tags, the AWS bill only breaks down costs **per service** (e.g. "Lambda: $12"), never per project — impossible to know what a specific workload costs when it spans several services.
- **User-defined cost allocation tags** let Billing and Cost Management (and Cost Explorer) filter/group costs by tag value, aggregating across services (Lambda + DynamoDB + S3 all tagged `Project = X`).
- Important nuance: tags exist on resources as soon as they're created, but must be **manually activated** in the Billing console before they appear in cost reports — tagging alone isn't enough.

### CloudWatch alarm mechanics
- `Period`: length (in seconds) of each measurement window, during which a statistic (Sum, Average...) is computed.
- `EvaluationPeriods`: how many consecutive windows must breach the threshold before the alarm state changes.
- Three possible states:
  - `OK` — evaluated, below threshold
  - `ALARM` — evaluated, above threshold
  - `INSUFFICIENT_DATA` — not enough data points to evaluate yet (e.g. right after alarm creation, or metric never received)
- Business criticality should drive the tuning: for a financial transaction processor, a false negative (missing a real failure) is far costlier than a false positive (an alert for a transient blip) — favoring low `evaluation_periods` for fast reactivity.
- `TreatMissingData` controls what happens when no data points arrive during a period (e.g. `missing`, `breaching`, `notBreaching`, `ignore`).

### Well-Architected Framework — pillars touched across all TPs so far
- **Security**: least privilege (S3 TP), avoiding hardcoded long-term credentials in favor of IAM roles (SQS/Lambda TP)
- **Reliability**: idempotent writes via `ConditionExpression` (DynamoDB TP), tolerating at-least-once delivery and retries
- **Performance Efficiency**: serverless architectures that scale automatically with load, no manual capacity planning
- **Cost Optimization**: pay-per-use billing (`PAY_PER_REQUEST`, Lambda per-invocation), cost allocation tags to track spend per project
- **Sustainability**: maximizing resource utilization (no idle always-on capacity), relying on AWS-managed infrastructure efficiency
- **Operational Excellence**: monitoring and alerting (this TP) to detect failures proactively rather than discovering them by chance

## ⚠️ Limitation discovered: MiniStack does not evaluate CloudWatch alarms

The alarm was created successfully with a correct configuration, but never transitioned out of `INSUFFICIENT_DATA`, even after triggering real Lambda errors. MiniStack's own documentation confirms this is expected: alarm evaluation is stubbed in their CloudWatch implementation, so alarms never actually transition to `ALARM` based on incoming metrics.

**Practical consequence:** Terraform configuration, metric dimensions, and thresholds can all be validated locally, but observing a real `OK → ALARM` state transition requires either a real AWS account (free tier) or the `aws cloudwatch set-alarm-state` command, which forces a temporary state manually for testing downstream actions (e.g. SNS notifications) without waiting on real metric evaluation.

## Cleanup

```bash
terraform destroy
```
