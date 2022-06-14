
# below block you might want to move to a file called versions.tf
terraform {
  required_version = ">1.0"
  required_providers {
    aws = {
      version = "~>3.6"
    }
  }

}

# you might want to move the block below to a file called aws_provider.tf
provider "aws" {
  region     = var.region
  access_key = var.awsstuff.aws_access_key_id
  secret_key = var.awsstuff.aws_secret_key
}


# This script creates 3 EC2s on the cloud in the Stretched on prem EPGs. At the moment we will just be deploying the single-page on the front end EC2 and the other 2 EC2s will just be up and running for back up for the on-prem.



#  Get VPC ID of ACI built VPC on AWS:

data "aws_vpcs" "vpc_id" {
  tags = {
    AciPolicyDnTag = "*Cisco_Live_TENANT*" # adding filter for our VPC - where XX is the id assigned to you 
  }
}


# Set a variable for vpcid value obtained
locals {
  vpcid = element(tolist(data.aws_vpcs.vpc_id.ids), 0)

}



# Get subnet IDs:

# We will filter the Subnet by using the tag

data "aws_subnet_ids" "subnet1" {
  vpc_id = local.vpcid
  filter{
  name= "tag:Name"
  values =["*150.0.1.0*"]
  }
}


data "aws_subnet_ids" "subnet2" {
  vpc_id = local.vpcid
  filter{
  name= "tag:Name"
  values =["*150.0.2.0*"]
  }
}



data "aws_subnet_ids" "subnet3" {
  vpc_id = local.vpcid
  filter{
  name= "tag:Name"
  values =["*150.0.3.0*"]
  }
}


# set variables for subnetIDs obtained.  Note we have to use type conversion "tolist" and then extract elements from the list


locals{
subnet1=element(tolist(data.aws_subnet_ids.subnet1.ids),0)
subnet2=element(tolist(data.aws_subnet_ids.subnet2.ids),0)
subnet3=element(tolist(data.aws_subnet_ids.subnet3.ids),0)

}



# Now let's get the corresponding security groups. We are once again filtering by using tags. 


data "aws_security_groups" "sg1" {

tags= {
 AciDnTag= "*epg1*"
}
}


data "aws_security_groups" "sg2" {

tags= {
 AciDnTag= "*epg2*"
}
}



data "aws_security_groups" "sg3" {

tags= {
 AciDnTag= "*epg3*"
}
}


locals{
securitygroup1=element(tolist(data.aws_security_groups.sg1.ids),0)
securitygroup2=element(tolist(data.aws_security_groups.sg2.ids),0)
securitygroup3=element(tolist(data.aws_security_groups.sg3.ids),0)
}

# Now we will create 6 interfaces- 2 for each EC2. One will have an EIP assigned for public access and one will not. 

resource "aws_network_interface" "ec2-1eth0" {
  subnet_id = local.subnet1
  private_ips =["150.0.1.5"]
}
resource "aws_network_interface" "ec2-2eth0" {
  subnet_id = local.subnet2
  private_ips=["150.0.2.5"]
}
resource "aws_network_interface" "ec2-3eth0" {
  subnet_id = local.subnet3
  private_ips=["150.0.3.5"]
}

resource "aws_eip" "eipforssh1" {
  vpc ="true"
  network_interface = aws_network_interface.ec2-1eth0.id
}

resource "aws_eip" "eipforssh2" {
  vpc ="true"
  network_interface = aws_network_interface.ec2-2eth0.id
}
resource "aws_eip" "eipforssh3" {
  vpc ="true"
  network_interface = aws_network_interface.ec2-3eth0.id
}


resource "aws_network_interface" "ec2-1eth1" {
  subnet_id = local.subnet1
  private_ips = ["150.0.1.6"]
}

resource "aws_network_interface" "ec2-2eth1" {
  subnet_id = local.subnet2
  private_ips = ["150.0.2.6"]
}

resource "aws_network_interface" "ec2-3eth1" {
  subnet_id = local.subnet3
  private_ips = ["150.0.3.6"]
}


# Upload public ssh key to AWS and create a new key named 'loginkey'
# Notice that this will upload my public key to AWS and use it for the EC2s.  
# This way, I can login with my private keys.
# Start by generating a pair using ssh-keygen command on the terminal. 
# Then either paste the public key here below(unsafe), or collect the public key info using a file read (safe).
# It is reccomended to create a folder called keypair and place your provate key and public key (.pub) there.

resource "aws_key_pair" "loginkey" {
  key_name = "loginkey" 
  public_key = file("${path.module}/keypair/privatekeyterraform.pub")  # #  path.module is in relation to the current directory, hence this assumes your key.pub is in the keypair folder 
  #public_key = "ssh-rsa <PASTEKeyHere> dcloud@dcloud-virtual-machine"
}


## Spin up the aws instances

#Start by selecting a relevant AMI 

data "aws_ami" "std_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


#create instances with 2 interfaces each, using the interface resources we got earlier 

resource "aws_instance" "ec2-1" {
  ami                         = data.aws_ami.std_ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.loginkey.key_name

    
  tags = {
    name = "ec2-1" 
  }
  network_interface {
    #this needs to be an elastic ip 
    device_index=0
    network_interface_id = "${aws_network_interface.ec2-1eth0.id}"
    
  }
  network_interface {
   device_index=1
   network_interface_id = "${aws_network_interface.ec2-1eth1.id}"
  } 
}

resource "aws_instance" "ec2-2" {
  ami                         = data.aws_ami.std_ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.loginkey.key_name

    
  tags = {
    name = "ec2-2" 
  }
  network_interface {
    #this needs to be an elastic ip 
    device_index=0
    network_interface_id = "${aws_network_interface.ec2-2eth0.id}"
    
  }
  network_interface {
   device_index=1
   network_interface_id = "${aws_network_interface.ec2-2eth1.id}"
  } 
}

resource "aws_instance" "ec2-3" {
  ami                         = data.aws_ami.std_ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.loginkey.key_name

    
  tags = {
    name = "ec2-3" 
  }
  network_interface {
    #this needs to be an elastic ip 
    device_index=0
    network_interface_id = "${aws_network_interface.ec2-3eth0.id}"
    
  }
  network_interface {
   device_index=1
   network_interface_id = "${aws_network_interface.ec2-3eth1.id}"
  } 
}


/**
  Note we are using triggers here to force the provisioners to run everytime "terraform apply" is used.   
  Normal behavior for provisioner is to run only during first run
  You may or maynot want to use triggers
**/



resource "null_resource" "update" {
  depends_on = [aws_instance.ec2-1]
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 30" # buy a little time to make sure ec2s are reachable
  }
}





#for DB EC2
# modify docker containers on the ec2  
resource "null_resource" "ec2-3e" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "remote-exec" {
    inline = [
      #here we can docker compose whatever we are interested in 
      
      #here we can docker compose whatever we are interested in 

      
      
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo chmod 666 /var/run/docker.sock",  
      
      # Code for Compose- CLContainers
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose --version",
      "sudo yum install git -y",
      "git clone https://github.com/achintya96/cisco-live-2022-aws-containers",
      "cd cisco-live-2022-aws-containers/ciscolive-containers",
      "cp docker-compose-db.yaml docker-compose.yaml",
      "docker-compose up -d"
      
      
     
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user" # this is the inbuilt ec2 user name for the used ami
      private_key = file("${path.module}/keypair/privatekeyterraform")
      host        = aws_instance.ec2-3.public_ip
    }
  }
}




#for Backend EC2
# modify docker containers on the ec2  
resource "null_resource" "ec2-2e" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "remote-exec" {
    inline = [
      #here we can docker compose whatever we are interested in 

      
      
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo chmod 666 /var/run/docker.sock",  
      
      # Code for Compose- SinglePage
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose --version",
      "sudo yum install git -y",
      "git clone https://github.com/achintya96/cisco-live-2022-aws-containers",
      "cd cisco-live-2022-aws-containers/ciscolive-containers",
      "cp docker-compose-be.yaml docker-compose.yaml",
      "docker-compose up -d"
          
 
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user" # this is the inbuilt ec2 user name for the used ami
      private_key = file("${path.module}/keypair/privatekeyterraform")
      host        = aws_instance.ec2-2.public_ip
    }
  }
}







# Now we will standup our singlepage container inside the front end EC2 
resource "null_resource" "EC2Commands" {
  depends_on = [null_resource.update]

  triggers = {
    build_number = timestamp()
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo chmod 666 /var/run/docker.sock",  
      
      # Code for Compose- SinglePage
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose --version",
      "sudo yum install git -y",
      "git clone https://github.com/achintya96/cisco-live-2022-aws-containers",
      "cd ~/cisco-live-2022-aws-containers/ciscolive-containers",
      "cp docker-compose-fe.yaml docker-compose.yaml",
      "docker-compose up -d"   
          
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user" # this is the inbuilt ec2 user name for the used ami
      private_key = file("${path.module}/keypair/privatekeyterraform")  # path to private key that you made 
      host        = aws_instance.ec2-1.public_ip

    }
  }
}




# adding an inbound rule to security groups for SSH 

resource "aws_security_group_rule" "secgroup1" {

 type = "ingress" 
 from_port = 22
 to_port = 22
 protocol = "tcp"
 security_group_id = local.securitygroup1
 cidr_blocks=["0.0.0.0/0"]
depends_on=[
aws_instance.ec2-1
]
}

resource "aws_security_group_rule" "secgroup1-internet" {

 type = "egress" 
 from_port = 443
 to_port = 443
 protocol = "tcp"
 security_group_id = local.securitygroup1
 cidr_blocks=["0.0.0.0/0"]
depends_on=[
aws_instance.ec2-1
]
}

resource "aws_security_group_rule" "secgroup1-internet-80expose" {

 type = "ingress" 
 from_port = 80
 to_port = 80
 protocol = "tcp"
 security_group_id = local.securitygroup1
 cidr_blocks=["0.0.0.0/0"]
depends_on=[
aws_instance.ec2-1
]
}








resource "aws_security_group_rule" "secgroup2" {

 type = "ingress" 
 from_port = 22
 to_port = 22
 protocol = "tcp"
 security_group_id = local.securitygroup2
 cidr_blocks=["0.0.0.0/0"]
depends_on=[
aws_instance.ec2-2
]
}

resource "aws_security_group_rule" "secgroup3" {

 type = "ingress" 
 from_port = 22
 to_port = 22
 protocol = "tcp"
 security_group_id = local.securitygroup3
 cidr_blocks=["0.0.0.0/0"]
depends_on=[
aws_instance.ec2-3
]
}






resource "aws_security_group_rule" "secgroup2-internet" {

 type = "egress" 
 from_port = 443
 to_port = 443
 protocol = "tcp"
 security_group_id = local.securitygroup2
 cidr_blocks=["0.0.0.0/0"]

}

resource "aws_security_group_rule" "secgroup2-internet-80expose" {

 type = "ingress" 
 from_port = 80
 to_port = 80
 protocol = "tcp"
 security_group_id = local.securitygroup2
 cidr_blocks=["0.0.0.0/0"]

}


resource "aws_security_group_rule" "secgroup3-internet" {

 type = "egress" 
 from_port = 443
 to_port = 443
 protocol = "tcp"
 security_group_id = local.securitygroup3
 cidr_blocks=["0.0.0.0/0"]

}

resource "aws_security_group_rule" "secgroup3-internet-80expose" {

 type = "ingress" 
 from_port = 80
 to_port = 80
 protocol = "tcp"
 security_group_id = local.securitygroup3
 cidr_blocks=["0.0.0.0/0"]

}







# adding a default route to the IGW 

data "aws_route_table" "table" {
 subnet_id= local.subnet1
}

data "aws_internet_gateway" "igw" {
 filter{
 name = "attachment.vpc-id"
 values = [local.vpcid]
 }
}

resource "aws_route" "r" {
 route_table_id = data.aws_route_table.table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id=data.aws_internet_gateway.igw.internet_gateway_id
  
  depends_on=[
  aws_instance.ec2-1,
  aws_instance.ec2-2,
  aws_instance.ec2-3
  ]
}




# Outputs:   (could put in separate file like output.tf also)

## show vpc_id
output "vpc_id" {
  #value = data.aws_vpcs.vpc_id.ids
  value = element(tolist(data.aws_vpcs.vpc_id.ids), 0)
}


## Show Public IPs
output "publicIP-ec2-1" {
  value = aws_instance.ec2-1.public_ip
}

output "publicIP-ec2-2" {
  value = aws_instance.ec2-2.public_ip
}

output "publicIP-ec2-3" {
  value =aws_instance.ec2-3.public_ip
}



