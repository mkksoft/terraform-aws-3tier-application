resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# security group for rds
resource "aws_security_group" "rds_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "Allow access to postgreSQL RDS"
  name = replace(upper(join("_", [
    var.module_spec["${var.environment}"].env_prefix,
    var.module_spec["${var.environment}"].module_name,
    "RDS"
  ])), "-", "_")
  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "RDS"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}

# alb security group rule 1
resource "aws_security_group_rule" "rds_rule1" {
  type                     = "ingress"
  description              = "Allow RDS access"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_db_instance" "postgres" {
  identifier                            = var.rds_data.identifier
  instance_class                        = var.rds_data.instance_class
  engine                                = var.rds_data.engine
  engine_version                        = var.rds_data.engine_version
  allocated_storage                     = var.rds_data.allocated_storage
  max_allocated_storage                 = var.rds_data.max_allocated_storage
  db_name                               = var.rds_data.db_name
  username                              = var.rds_data.username
  password                              = random_password.password.result
  port                                  = var.rds_data.port
  multi_az                              = var.rds_data.multi_az
  db_subnet_group_name                  = aws_db_subnet_group.rds.id
  vpc_security_group_ids                = [aws_security_group.rds_sg.id]
  maintenance_window                    = var.rds_data.maintenance_window
  backup_window                         = var.rds_data.backup_window
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  backup_retention_period               = var.rds_data.backup_retention_period
  skip_final_snapshot                   = var.rds_data.skip_final_snapshot
  performance_insights_enabled          = var.rds_data.performance_insights_enabled
  performance_insights_retention_period = var.rds_data.performance_insights_retention_period
  storage_encrypted                     = var.rds_data.storage_encrypted
  performance_insights_kms_key_id       = aws_kms_key.sbkms.arn
}
