output "access_key_id" {
  value = aws_iam_access_key.payment_service_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.payment_service_key.secret
  sensitive = true
}
