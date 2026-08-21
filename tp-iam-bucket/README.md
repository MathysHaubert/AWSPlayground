# Exercise — IAM & Least Privilege with S3 (CLF-C02 revision)

**Type:** Setup / certification revision
**Level:** Beginner-intermediate

## Goal

Create an IAM user restricted to a single S3 bucket, write the corresponding policy, and understand the mechanics of bucket-level vs object-level permissions.

## What was built

- 2 S3 buckets (`allowed` and `forbidden`)
- 1 IAM user (`restricted-user`) with a permanent access key
- 1 IAM policy granting `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on the `allowed` bucket only
- Policy attached directly to the user (for a real team project: attach to a group instead)
- A dedicated AWS CLI profile (`--profile restricted`) to test as that user

## Key concepts to remember for the exam

### Groups vs Roles
- **Groups**: best practice for managing permissions of **human** users. Attach the policy to the group, not to the individual user.
- **Roles**: for **temporary** permissions or **non-human** entities (EC2, Lambda, third-party accounts). Generate temporary credentials via STS — never hardcode long-term keys.
- Phrase worth remembering: *"Never hardcode credentials — use IAM roles instead."*

### Bucket-level vs object-level ARN
A complete S3 policy almost always needs both ARN forms:

| Action | Required ARN | Example |
|---|---|---|
| `s3:ListBucket` | Bucket (no `/*`) | `arn:aws:s3:::my-bucket` |
| `s3:GetObject`, `s3:PutObject` | Objects (with `/*`) | `arn:aws:s3:::my-bucket/*` |
| `s3:ListAllMyBuckets` | Entire account | `Resource = "*"` |

Classic mistake: including only the object-level ARN (`/*`) and then wondering why `ListBucket` fails, or the reverse.

### Permanent access keys vs temporary credentials
`aws_iam_access_key` (or the IAM console) generates **permanent** credentials, valid until manually revoked — unlike credentials obtained through an assumed role (STS), which expire automatically.

## Cleanup

```bash
terraform destroy
```
