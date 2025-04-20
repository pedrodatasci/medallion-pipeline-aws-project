resource "random_password" "redshift_user_password" {
  length           = 16
  override_characters = "!@#%^*-_=+"
  special          = true
  upper            = true
  lower            = true
  number           = true
  # evita barras, aspas e espaços que quebram o SQL
  exclude_characters = "/@\" '\\"
}

resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "read_user_secret" {
  name = "redshift-brewery-readonly-user-${random_id.secret_suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "read_user_secret_version" {
  secret_id     = aws_secretsmanager_secret.read_user_secret.id
  secret_string = jsonencode({
    username = "brewery_user"
    password = random_password.redshift_user_password.result
  })
}