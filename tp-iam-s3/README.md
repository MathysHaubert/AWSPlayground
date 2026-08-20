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

## ⚠️ Limitation discovered: MiniStack does not enforce IAM

Tested in practice: a user with a restrictive policy (access to a single bucket) was able to list **all** buckets and access the "forbidden" bucket without any error. Cause: MiniStack (like LocalStack's free edition) performs **no real IAM policy evaluation** — every authenticated request is accepted regardless of its content.

> Official MiniStack documentation: *"No real VPC networking, no real IAM policy evaluation (same as LocalStack free)."*

**Practical consequence:** you can write and validate the *syntax* of an IAM policy locally, but you cannot observe a real `AccessDenied` without a real AWS account (free tier) or a paid/alternative emulator with IAM enforcement (e.g. LocalStack Pro, fakecloud in `--iam strict` mode).

**For the exam:** knowing the expected behavior on real AWS remains essential even without being able to test it locally — this is exactly the kind of scenario ("why does this command fail when the policy looks correct") that CLF-C02 tests via multiple-choice questions.

## Cleanup

```bash
terraform destroy
```
