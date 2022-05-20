resource "aws_kms_key" "sbkms" {
  description              = "KMS key for SB"
  deletion_window_in_days  = 10
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  tags = {
    Name = "SBKMS"
  }
}

resource "aws_kms_alias" "sbkms_alias" {
  name          = "alias/sbkms"
  target_key_id = aws_kms_key.sbkms.key_id
}