

#  Define versions 

terraform {
  required_providers {
    mso = {
      source  = "ciscodevnet/mso"
      version = "= 0.5.0"
    }
  }
  required_version = ">= 1.1.6"
}



#  Define Providers  If using local ND user, comment out the domain.

provider "mso" {
  username = var.creds.username
  password = var.creds.password
  url      = var.creds.url
#  domain   = var.creds.domain
  insecure = "true"
  platform = "nd"
}

