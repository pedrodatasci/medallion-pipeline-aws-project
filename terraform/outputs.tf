output "bucket_name" {
  value = aws_s3_bucket.data_lake.bucket
}

output "bronze_job_name" {
  value = aws_glue_job.bronze_job.name
}

output "silver_job_name" {
  value = aws_glue_job.silver_job.name
}

output "redshift_workgroup_name" {
  value = aws_redshiftserverless_workgroup.this.workgroup_name
}

output "redshift_database_name" {
  value = aws_redshiftserverless_namespace.this.db_name
}

output "redshift_endpoint" {
  value = aws_redshiftserverless_workgroup.this.endpoint[0].address
}

output "glue_exec_role_arn" {
  value = aws_iam_role.glue_exec_role.arn
}

output "redshift_copy_role_arn" {
  value = aws_iam_role.redshift_copy_role.arn
}

output "redshift_read_user_secret_name" {
  value = aws_secretsmanager_secret.read_user_secret.name
}