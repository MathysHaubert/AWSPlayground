# Imagine that a colleague wrote it before going on holiday, and that the production team is constantly reporting AccessDenied errors.

resource "aws_s3_bucket" "payments_data" {
  bucket = "clf-tp-payments-data"
}

resource "aws_iam_user" "payment_service" {
  name = "payment-service-user"
}

resource "aws_iam_access_key" "payment_service_key" {
  user = aws_iam_user.payment_service.name
}

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

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.payment_service.name
  policy_arn = aws_iam_policy.payments_read_write.arn
}
