resource "aws_s3_bucket" "data_lake" {
  bucket = "openbrewery-data-${random_id.suffix.hex}"
  force_destroy = true
}