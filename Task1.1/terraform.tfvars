#  Values of variables to override default values defined in variables.tf



aws_site_name = "AWSSite" # the site name for the AWS site as seen on ND

# Remember that the tenant values are stored in Variables.tf, please change them there.
schema_name = "Cisco_Live_SCHEMA"  
template_name= "Cisco_Live_TEMPLATE"            # use a template name as you wish
vrf_name      = "CLUS_VRF"                       # use a vrf name as you wish
anp_name      = "CLUS_ANP"                       # use a ANP name as you wish
region_name   = "us-east-1"                  



epg_name_1      = "epg1"        
epg_selector_value_1 = "150.0.1.0/24"
bd_name_1= "bd_name_1"


epg_name_2     = "epg2"        
epg_selector_value_2 = "150.0.2.0/24"
bd_name_2 = "bd_name_2"



epg_name_3      = "epg3"        
bd_name_3 = "bd_name_3"
epg_selector_value_3 = "150.0.3.0/24"


cidr_ip = "150.0.0.0/16" # CIDR IP as you wish for the VPC in AWS tenant account

subnet1 = "150.0.1.0/24" # subnet should belong to CIDR
zone1   = "us-east-1b"    

subnet2 = "150.0.2.0/24" # subnet should belong to CIDR
zone2   = "us-east-1b"    

subnet3 = "150.0.3.0/24" # subnet should belong to CIDR
zone3   = "us-east-1b"    



