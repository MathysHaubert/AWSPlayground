
resource "aws_secretsmanager_secret" "payment_api_key" {
  name = "payment-partner-api-key"
}

resource "aws_secretsmanager_secret_version" "payment_api_key_value" {
  secret_id     = aws_secretsmanager_secret.payment_api_key.id
  secret_string = jsonencode({
    api_key = "sk_test_51H8xJ2K9fictitious"
  })
}

resource "aws_iam_policy" "read_payment_secret" {
  name = "read-payment-api-key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.payment_api_key.arn
      }
    ]
  })
}

resource "aws_iam_role" "lambda_secrets_exec" {
  name = "lambda-secrets-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_secrets_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secret_read" {
  role       = aws_iam_role.lambda_secrets_exec.name
  policy_arn = aws_iam_policy.read_payment_secret.arn
}

resource "aws_lambda_function" "lambda_python" {
  role = aws_iam_role.lambda_secrets_exec.arn
  filename = "lambda_function.zip"
  function_name = "handler"
  handler = "lambda_function.handler"
  runtime = "python3.12"
  source_code_hash = filebase64sha256("lambda_function.zip")
}
