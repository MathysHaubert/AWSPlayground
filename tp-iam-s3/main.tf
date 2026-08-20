resource "aws_s3_bucket" "allowed" {
  bucket = "clf-tp-allowed-bucket"
}

resource "aws_s3_bucket" "forbidden" {
  bucket = "clf-tp-forbidden-bucket"
}

resource "aws_iam_user" "restricted" {
  name = "restricted-user"
}

resource "aws_iam_access_key" "restricted_key" {
  user = aws_iam_user.restricted.name
}

resource "aws_iam_policy" "s3_restricted_access" {
  name = "s3-restricted-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject","s3:ListBucket"]
        Resource = [
          aws_s3_bucket.allowed.arn,
          "${aws_s3_bucket.allowed.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach" {
  user = aws_iam_user.restricted.name
  policy_arn = aws_iam_policy.s3_restricted_access.arn
}
