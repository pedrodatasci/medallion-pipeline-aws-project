resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = "medallion-namespace"
  db_name        = "analytics_db"
}

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name         = "medallion-workgroup"
  namespace_name         = aws_redshiftserverless_namespace.this.namespace_name
  publicly_accessible    = true
  base_capacity          = 8
  enhanced_vpc_routing   = false

  tags = {
    Environment = "dev"
  }
}
