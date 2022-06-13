#Main TF Script to create Cloud Resources on AWS 

#  Define data sources

data "mso_site" "aws_site" {
  name = var.aws_site_name
}


data "mso_user" "user1" {
  username = "CLUS-user01"
}


#  Define your terraform script here put in file main.tf



# Creating a tenant with the desired name 
resource "mso_tenant" "tenant" {
  name         = var.tenant_stuff.tenant_name
  display_name = var.tenant_stuff.display_name
  description  = var.tenant_stuff.description
  site_associations {
    site_id           = data.mso_site.aws_site.id
    vendor            = "aws"
    aws_account_id    = var.awsstuff.aws_account_id
    aws_access_key_id = var.awsstuff.aws_access_key_id
    aws_secret_key    = var.awsstuff.aws_secret_key
  }
  user_associations { user_id = data.mso_user.user1.id }
}



## create schema

resource "mso_schema" "schema1" {
  name          = var.schema_name
  template_name = var.template_name
  tenant_id     = mso_tenant.tenant.id
  depends_on = [
  mso_tenant.tenant
  ]
}




## Associate Schema / template with Site

resource "mso_schema_site" "aws_site" {
  schema_id     = mso_schema.schema1.id
  site_id       = data.mso_site.aws_site.id
  template_name = mso_schema.schema1.template_name
  depends_on = [
  mso_tenant.tenant,
  mso_schema.schema1
  ]
}




## Create VRF and associate with template

resource "mso_schema_template_vrf" "vrf1" {
  schema_id        = mso_schema.schema1.id
  template         = mso_schema.schema1.template_name
  name             = var.vrf_name
  display_name     = var.vrf_name
  layer3_multicast = false
  vzany            = false
}

#######

# Associate VRF with Schema

resource "mso_schema_site_vrf" "aws_site" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema_site.aws_site.template_name
  site_id       = data.mso_site.aws_site.id
  vrf_name      = mso_schema_template_vrf.vrf1.name
}



## associate with Region and zones in Site Local Templates
resource "mso_schema_site_vrf_region" "vrfRegion" {
  schema_id          = mso_schema.schema1.id
  template_name      = mso_schema_site.aws_site.template_name
  site_id            = data.mso_site.aws_site.id
  vrf_name           = mso_schema_site_vrf.aws_site.vrf_name
  region_name        = var.region_name
  vpn_gateway        = true    # required for commmunication between cloud and onprem 
  hub_network_enable = false
  cidr {
    cidr_ip = var.cidr_ip
    primary = true

    subnet {
      ip    = var.subnet1
      zone  = var.zone1
      usage = "gateway"
    }

    subnet {
      ip    = var.subnet2
      zone  = var.zone2

    }

    subnet {
      ip   = var.subnet3
      zone = var.zone3
      #usage = "not_used_since_each_zone_can_have_1__gateway"
    }

  }

}

## create ANP

resource "mso_schema_template_anp" "anp1" {
  schema_id    = mso_schema.schema1.id
  template     = var.template_name
  name         = var.anp_name
  display_name = var.anp_name
  depends_on = [
     mso_tenant.tenant,
  mso_schema.schema1,
  mso_schema_site.aws_site,
  mso_schema_template_vrf.vrf1,
  mso_schema_site_vrf.aws_site,
  mso_schema_site_vrf_region.vrfRegion
  ]
}





resource "mso_schema_site_anp" "anp1" {
  schema_id     = mso_schema.schema1.id
  anp_name      = mso_schema_template_anp.anp1.name
  template_name = var.template_name
  site_id       = data.mso_site.aws_site.id

}



# EPG 1
resource "mso_schema_template_anp_epg" "anp_epg_1" {
  schema_id                  = mso_schema.schema1.id
  template_name              = mso_schema.schema1.template_name
  anp_name                   = mso_schema_template_anp.anp1.name
  name                       = var.epg_name_1
  bd_name                    = var.bd_name_1
  vrf_name                   = mso_schema_template_vrf.vrf1.name
  display_name               = var.epg_name_1
  useg_epg                   = false
  intra_epg                  = "unenforced"
  intersite_multicast_source = false
  preferred_group            = false
}

resource "mso_schema_site_anp_epg" "site_anp_epg_1" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema_site.aws_site.template_name
  site_id       = data.mso_site.aws_site.id
  anp_name      = mso_schema_site_anp.anp1.anp_name
  epg_name      = mso_schema_template_anp_epg.anp_epg_1.name
}

resource "mso_schema_template_bd" "bridge_domain_1" {
  schema_id              = mso_schema.schema1.id
  template_name          = mso_schema.schema1.template_name
  name                   = var.bd_name_1
  display_name           = "BD_1"
  vrf_name               = mso_schema_template_vrf.vrf1.name
  layer2_unknown_unicast = "proxy" 
}




### define epg selector

resource "mso_schema_site_anp_epg_selector" "epgSel1" {
  schema_id     = mso_schema.schema1.id
  site_id       = data.mso_site.aws_site.id
  template_name = mso_schema_site.aws_site.template_name
  anp_name      = mso_schema_site_anp_epg.site_anp_epg_1.anp_name
  epg_name      = mso_schema_site_anp_epg.site_anp_epg_1.epg_name
  name          = "epgSel1"
  expressions {
    key      = "ipAddress"
    operator = "equals"
    value    = var.epg_selector_value_1
  }
}






### EPG 2


resource "mso_schema_template_anp_epg" "anp_epg_2" {
  schema_id                  = mso_schema.schema1.id
  template_name              = mso_schema.schema1.template_name
  anp_name                   = mso_schema_template_anp.anp1.name
  name                       = var.epg_name_2
  bd_name                    = var.bd_name_2
  vrf_name                   = mso_schema_template_vrf.vrf1.name
  display_name               = var.epg_name_2
  useg_epg                   = false
  intra_epg                  = "unenforced"
  intersite_multicast_source = false
  preferred_group            = false
}

resource "mso_schema_site_anp_epg" "site_anp_epg_2" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema_site.aws_site.template_name
  site_id       = data.mso_site.aws_site.id
  anp_name      = mso_schema_site_anp.anp1.anp_name
  epg_name      = mso_schema_template_anp_epg.anp_epg_2.name
}

resource "mso_schema_template_bd" "bridge_domain_2" {
  schema_id              = mso_schema.schema1.id
  template_name          = mso_schema.schema1.template_name
  name                   = var.bd_name_2
  display_name           = "BD_2"
  vrf_name               = mso_schema_template_vrf.vrf1.name
  layer2_unknown_unicast = "proxy" 
}




resource "mso_schema_site_anp_epg_selector" "epgSel2" {
  schema_id     = mso_schema.schema1.id
  site_id       = data.mso_site.aws_site.id
  template_name = mso_schema_site.aws_site.template_name
  anp_name      = mso_schema_site_anp_epg.site_anp_epg_2.anp_name
  epg_name      = mso_schema_site_anp_epg.site_anp_epg_2.epg_name
  name          = "epgSel2"
  expressions {
    key      = "ipAddress"
    operator = "equals"
    value    = var.epg_selector_value_2
  }
}



### EPG 3

resource "mso_schema_template_anp_epg" "anp_epg_3" {
  schema_id                  = mso_schema.schema1.id
  template_name              = mso_schema.schema1.template_name
  anp_name                   = mso_schema_template_anp.anp1.name
  name                       = var.epg_name_3
  bd_name                    = var.bd_name_3
  vrf_name                   = mso_schema_template_vrf.vrf1.name
  display_name               = var.epg_name_3
  useg_epg                   = false
  intra_epg                  = "unenforced"
  intersite_multicast_source = false
  preferred_group            = false
}

resource "mso_schema_site_anp_epg" "site_anp_epg_3" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema_site.aws_site.template_name
  site_id       = data.mso_site.aws_site.id
  anp_name      = mso_schema_site_anp.anp1.anp_name
  epg_name      = mso_schema_template_anp_epg.anp_epg_3.name
}

resource "mso_schema_template_bd" "bridge_domain_3" {
  schema_id              = mso_schema.schema1.id
  template_name          = mso_schema.schema1.template_name
  name                   = var.bd_name_3
  display_name           = "BD_3"
  vrf_name               = mso_schema_template_vrf.vrf1.name
  layer2_unknown_unicast = "proxy" 
}




resource "mso_schema_site_anp_epg_selector" "epgSel3" {
  schema_id     = mso_schema.schema1.id
  site_id       = data.mso_site.aws_site.id
  template_name = mso_schema_site.aws_site.template_name
  anp_name      = mso_schema_site_anp_epg.site_anp_epg_3.anp_name
  epg_name      = mso_schema_site_anp_epg.site_anp_epg_3.epg_name
  name          = "epgSel3"
  expressions {
    key      = "ipAddress"
    operator = "equals"
    value    = var.epg_selector_value_3
  }
}



#Contracts:

resource "mso_schema_template_filter_entry" "filter_entry" {
  schema_id          = mso_schema.schema1.id
  template_name      = mso_schema.schema1.template_name
  name               = "Any"
  display_name       = "Any"
  entry_name         = "Any"
  entry_display_name = "Any"
  destination_from   = "unspecified"
  destination_to     = "unspecified"
  source_from        = "unspecified"
  source_to          = "unspecified"
  arp_flag           = "unspecified"
}


resource "mso_schema_template_contract" "template_contract" {
  schema_id     = mso_schema_template_filter_entry.filter_entry.schema_id
  template_name = mso_schema_template_filter_entry.filter_entry.template_name
  contract_name = try("C1")
  display_name  = try("C1")
  scope         = "context"
  directives    = ["none"]
}

### Associate filter with Contract
resource "mso_schema_template_contract_filter" "Any" {
  schema_id     = mso_schema_template_contract.template_contract.schema_id
  template_name = mso_schema_template_contract.template_contract.template_name
  contract_name = mso_schema_template_contract.template_contract.contract_name # "C1"
  filter_type   = "bothWay"
  filter_name   = "Any"
  directives    = ["none", "log"]
}




#### add Contract Provider and Consumer to EPg
resource "mso_schema_template_anp_epg_contract" "c1_epg_provider_1" {
  schema_id         = mso_schema_template_contract_filter.Any.schema_id
  template_name     = mso_schema_template_contract_filter.Any.template_name
  anp_name          = mso_schema_site_anp_epg.site_anp_epg_1.anp_name
  epg_name          = mso_schema_site_anp_epg.site_anp_epg_1.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "provider"

}


resource "mso_schema_template_anp_epg_contract" "c1_epg_consumer_1" {
  schema_id         = mso_schema_template_anp_epg_contract.c1_epg_provider_1.schema_id
  template_name     = mso_schema_template_anp_epg_contract.c1_epg_provider_1.template_name
  anp_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_1.anp_name
  epg_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_1.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "consumer"

}



#### add Contract Provider and Consumer to EPg
resource "mso_schema_template_anp_epg_contract" "c1_epg_provider_2" {
  schema_id         = mso_schema_template_contract_filter.Any.schema_id
  template_name     = mso_schema_template_contract_filter.Any.template_name
  anp_name          = mso_schema_site_anp_epg.site_anp_epg_2.anp_name
  epg_name          = mso_schema_site_anp_epg.site_anp_epg_2.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "provider"

}


resource "mso_schema_template_anp_epg_contract" "c1_epg_consumer_2" {
  schema_id         = mso_schema_template_anp_epg_contract.c1_epg_provider_2.schema_id
  template_name     = mso_schema_template_anp_epg_contract.c1_epg_provider_2.template_name
  anp_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_2.anp_name
  epg_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_2.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "consumer"

}



#### add Contract Provider and Consumer to EPg
resource "mso_schema_template_anp_epg_contract" "c1_epg_provider_3" {
  schema_id         = mso_schema_template_contract_filter.Any.schema_id
  template_name     = mso_schema_template_contract_filter.Any.template_name
  anp_name          = mso_schema_site_anp_epg.site_anp_epg_3.anp_name
  epg_name          = mso_schema_site_anp_epg.site_anp_epg_3.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "provider"

}


resource "mso_schema_template_anp_epg_contract" "c1_epg_consumer_3" {
  schema_id         = mso_schema_template_anp_epg_contract.c1_epg_provider_3.schema_id
  template_name     = mso_schema_template_anp_epg_contract.c1_epg_provider_3.template_name
  anp_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_3.anp_name
  epg_name          = mso_schema_template_anp_epg_contract.c1_epg_provider_3.epg_name
  contract_name     = mso_schema_template_contract.template_contract.contract_name
  relationship_type = "consumer"

}






### Deploy Template:
resource "mso_schema_template_deploy" "template_deployer" {
  schema_id     = mso_schema.schema1.id
  template_name = mso_schema.schema1.template_name
  depends_on = [
    mso_tenant.tenant,
    mso_schema.schema1,
    mso_schema_site.aws_site,
    mso_schema_template_vrf.vrf1,
    mso_schema_site_vrf.aws_site,
    mso_schema_site_vrf_region.vrfRegion,
    mso_schema_template_anp.anp1,
    
mso_schema_template_bd.bridge_domain_1,
#mso_schema_site_bd.bd1,
mso_schema_site_anp_epg_selector.epgSel1,

mso_schema_template_bd.bridge_domain_2,
#mso_schema_site_bd.bd2,
mso_schema_site_anp_epg_selector.epgSel2,

mso_schema_template_bd.bridge_domain_3,
#mso_schema_site_bd.bd3,
mso_schema_site_anp_epg_selector.epgSel3,

mso_schema_template_anp_epg_contract.c1_epg_provider_1,
mso_schema_template_anp_epg_contract.c1_epg_consumer_1,
mso_schema_template_anp_epg_contract.c1_epg_provider_2,
mso_schema_template_anp_epg_contract.c1_epg_consumer_2,
mso_schema_template_anp_epg_contract.c1_epg_provider_3,
mso_schema_template_anp_epg_contract.c1_epg_consumer_3
  ]
  #undeploy = true
}


