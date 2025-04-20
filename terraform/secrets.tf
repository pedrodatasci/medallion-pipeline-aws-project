resource "random_password" "redshift_user_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "read_user_secret" {
  name = "redshift-brewery-readonly-user-v1"
}

resource "aws_secretsmanager_secret_version" "read_user_secret_version" {
  secret_id     = aws_secretsmanager_secret.read_user_secret.id
  secret_string = jsonencode({
    username = "brewery_user"
    password = random_password.redshift_user_password.result
  })
}
