variable "awsstuff" {
  type = map(any)
  default = {
    aws_account_id         = "000000000000"
    is_aws_account_trusted = false
    aws_access_key_id      = "00000000000000000000"
    aws_secret_key         = "0000000000000000000000000000000000000000000"
  }
}
