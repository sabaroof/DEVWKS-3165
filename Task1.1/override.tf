#  use this override.tf to put in confidential data


#  Populate values based on your AWS values
variable "awsstuff" {
  type = object({
    aws_account_id    = string
    aws_access_key_id = string
    aws_secret_key    = string
  })
  default = {
    aws_account_id    = "0000000000000000"                         #Enter Aws Account ID for your tenant account 
    aws_access_key_id = "000000000000000000000000000"                        #Enter Acccess Key ID for your tenant account 
    aws_secret_key    = "000000000000000000000000000000000"   #Enter Secret Key for your tenant account 
  }
}



#  Populate values based on your ND cofigiration
variable "creds" {
  type = map(any)
  default = {
    username = "CLUS-userXX"              
    password = "CLUS-userXX-123!"  # Insert admin password for NDO 
    url      = "https://198.19.202.12/"    #Insert NDO IP
  }
}

# Populate Tenant Values

variable "tenant_stuff" {
  type = object({
    tenant_name  = string
    display_name = string
    description  = string
  })
  default = {
    tenant_name  = "Cisco_Live_TENANT_XX" # change XX to your assigned user name 
    display_name = "Cisco_Live_TENANT_XX" # change XX to your assigned user name 
    description  = " Terraform Created Tenant for user XX" # change XX to your assigned user name 
  }
}
