# this is the file that defines the variables.  The values should be specified in terraform.tfvars

variable "instance_type" { default = "t2.micro" }


variable "awsstuff" {
  type = map(any)
  default = {
    aws_account_id         = "someValue"
    is_aws_account_trusted = false
    aws_access_key_id      = "someValue"
    aws_secret_key         = "someValue"
  }
}

variable "region" {
  default = "us-east-1"
}



