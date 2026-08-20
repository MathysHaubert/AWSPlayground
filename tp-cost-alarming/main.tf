resource "aws_sqs_queue" "transaction_queue" {
  name = "transaction-queue"
  visibility_timeout_seconds = 60
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-sqs-exec-role"

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
  role       = aws_iam_role.lambda_exec.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "transaction_processor" {
  function_name    = "transaction-processor"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  tags = {
    Project = "clf-tp-transactions"
    Environment = "dev"
    CostCenter = "fintech-payments"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.transaction_queue.arn
  function_name    = aws_lambda_function.transaction_processor.arn
  batch_size       = 10
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "transaction-processor-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name          = "Errors"
  namespace            = "AWS/Lambda"
  period               = 60
  statistic            = "Sum"
  threshold            = 0

  dimensions = {
    FunctionName = aws_lambda_function.transaction_processor.function_name
  }

  alarm_description = "Triggers when the Lambda fails at least once"
}
