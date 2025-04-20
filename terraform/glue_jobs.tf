resource "aws_glue_job" "bronze_job" {
  name     = "glue-bronze-job"
  role_arn = aws_iam_role.glue_exec_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.data_lake.bucket}/scripts/bronze_glue.py"
    python_version  = "3"
  }

  max_capacity = 2
}

resource "aws_glue_job" "silver_job" {
  name     = "glue-silver-job"
  role_arn = aws_iam_role.glue_exec_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.data_lake.bucket}/scripts/silver_glue.py"
    python_version  = "3"
  }

  max_capacity = 2
}