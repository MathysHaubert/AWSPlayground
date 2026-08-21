# Exercise — Fixing a Broken IAM Policy (CLF-C02 revision)

**Type:** Fix / debugging
**Level:** Beginner-intermediate

## Goal

Debug a Terraform-managed IAM policy causing persistent `AccessDenied` errors for a production service, using LocalStack Pro with real IAM enforcement (`ENFORCE_IAM=1`) — a follow-up to the S3/IAM setup TP, this time practicing audit and repair rather than initial setup.

## Scenario

A `payment-service-user` needs read/write access to a single S3 bucket (`clf-tp-payments-data`). The service reports constant `AccessDenied` errors in production.

## Broken version

```hcl
resource "aws_iam_policy" "payments_read_write" {
  name = "payments-read-write"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadWrite"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.payments_data.arn,
          "${aws_s3_bucket.payments_data.arn}/*"
        ]
      },
      {
        Sid      = "TemporaryTestingBlock"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.payments_data.arn}/*"
      }
    ]
  })
}
```

**Root cause:** a second statement (`TemporaryTestingBlock`), apparently left in place after a debugging session, explicitly denies all S3 actions (`s3:*`) on the object-level ARN (`.../*`). Since **an explicit Deny always overrides an Allow** in IAM evaluation logic — regardless of statement order or which policy it comes from — this silently blocked `GetObject` and `PutObject`.

**Why `ListBucket` still worked while `GetObject`/`PutObject` failed:** the Deny's `Resource` only covers the object-level ARN (`/*`). `ListBucket` operates on the bucket-level ARN (no `/*`), which the Deny never targeted — so it remained unaffected while object-level actions were blocked.

## Fixed version

```hcl
resource "aws_iam_policy" "payments_read_write" {
  name = "payments-read-write"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadWrite"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.payments_data.arn,
          "${aws_s3_bucket.payments_data.arn}/*"
        ]
      }
    ]
  })
}
```

Removing the leftover Deny statement restored full read/write access, verified with a real `PutObject` upload succeeding after the fix.

## Key concepts to remember for the exam

- **Explicit Deny always wins.** No Allow statement, from any attached policy, can override an explicit Deny on the same action/resource.
- **Deny scope matters just as much as Allow scope.** A Deny with a narrower `Resource` (only `/*`, missing the bucket-level ARN) doesn't block bucket-level actions like `ListBucket` — asymmetric ARN scoping applies to Deny statements exactly as it does to Allow statements.
- **Risk asymmetry between under- and over-permissioning:** a missing Allow fails loudly (`AccessDenied`, visible immediately). A forgotten Deny that should still be blocking something dangerous fails silently — nothing errors, so nobody notices the excess access until an audit catches it. This is part of why tools like **IAM Access Analyzer** exist — to catch permission issues that no runtime error would ever surface on its own.

## Tooling note

This TP used **LocalStack Pro** (via the GitHub Student Developer Pack) with `ENFORCE_IAM=1`, not MiniStack — real `AccessDenied` responses were observed directly, unlike the earlier MiniStack-based IAM TP where policy enforcement was not simulated at all.

## Cleanup

```bash
terraform destroy
```
