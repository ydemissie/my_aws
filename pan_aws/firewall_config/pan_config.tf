#This configuration file depends on variables and the panos provider for connection, all defined in separate configuration files

/*
results in successful 'terraform apply' on the first run. However, on all subsequent runs terraform wants to destroy the instance 
and re-create it, even if nothing has changed. I found that removing the hard-coded EBS volume and allowing the AMI to provide 
the EBS details as needed results in subsequent 'terraform apply' commands completing successfully while leaving existing 
firewall instances in place. Therefore do not had code EBS the ebs_block_device.
*/

#Create interface managment profile
resource "panos_management_profile" "mgt_prof" {
  name = "Allow ping"
  ping = true
}

#Create interfaces
resource "panos_ethernet_interface" "eth1" {
  name                      = "ethernet1/1"
  mode                      = "layer3"
  vsys                      = "vsys1"
  enable_dhcp               = true
  create_dhcp_default_route = true
}

resource "panos_ethernet_interface" "eth2" {
  name                      = "ethernet1/2"
  mode                      = "layer3"
  vsys                      = "vsys1"
  enable_dhcp               = true
  create_dhcp_default_route = false
}

#Configure default virtual router
resource "panos_virtual_router" "default_vr" {
  name       = "default"
  interfaces = ["ethernet1/1", "ethernet1/2"]
  depends_on = ["panos_ethernet_interface.eth1", "panos_ethernet_interface.eth2"]
}

#Create zones for inside and outside
resource "panos_zone" "untrust" {
  name       = "Untrust"
  mode       = "layer3"
  interfaces = ["${panos_ethernet_interface.eth1.name}"]
}

resource "panos_zone" "trust" {
  name       = "Trust"
  mode       = "layer3"
  interfaces = ["${panos_ethernet_interface.eth2.name}"]
}

#Create service objects
resource "panos_service_object" "service_tcp_221" {
  name             = "service-tcp-221"
  vsys             = "vsys1"
  protocol         = "tcp"
  description      = "Service object to map port 22 to 221"
  destination_port = "221"
}

resource "panos_service_object" "service_tcp_222" {
  name             = "service-tcp-222"
  vsys             = "vsys1"
  protocol         = "tcp"
  description      = "Service object to map port 22 to 222"
  destination_port = "222"
}

resource "panos_service_object" "http-81" {
  name             = "http-81"
  vsys             = "vsys1"
  protocol         = "tcp"
  description      = "Service object to map port 22 to 222"
  destination_port = "81"
}

#Create NAT rules
resource "panos_nat_policy" "nat_rule_for_web_ssh" {
  name                  = "web_ssh"
  source_zones          = ["Untrust"]
  destination_zone      = "Untrust"
  source_addresses      = ["any"]
  destination_addresses = ["10.0.0.100"]
  service               = "service-tcp-221"
  sat_type              = "dynamic-ip-and-port"
  sat_address_type      = "interface-address"
  sat_interface         = "ethernet1/2"
  dat_address           = "10.0.1.101"
  dat_port              = "22"

  depends_on = ["panos_service_object.service_tcp_221", "panos_zone.untrust",
    "panos_zone.trust",
    "panos_ethernet_interface.eth2",
  ]
}

resource "panos_nat_policy" "nat_rule_for_web_http" {
  name                  = "web_http"
  source_zones          = ["Untrust"]
  destination_zone      = "Untrust"
  source_addresses      = ["any"]
  destination_addresses = ["10.0.0.100"]
  service               = "service-http"
  sat_type              = "dynamic-ip-and-port"
  sat_address_type      = "interface-address"
  sat_interface         = "ethernet1/2"
  dat_address           = "10.0.1.101"
  dat_port              = "80"
  depends_on            = ["panos_zone.untrust", "panos_zone.trust", "panos_ethernet_interface.eth2"]
}

resource "panos_nat_policy" "outbound_nat" {
  name                  = "NAT_All_Out"
  source_zones          = ["Trust"]
  destination_zone      = "Untrust"
  source_addresses      = ["any"]
  destination_addresses = ["any"]
  sat_type              = "dynamic-ip-and-port"
  sat_address_type      = "interface-address"
  sat_interface         = "ethernet1/1"
  depends_on            = ["panos_zone.untrust", "panos_zone.trust", "panos_ethernet_interface.eth1"]
}

resource "panos_nat_policy" "nat_rule_for_web_ssh2" {
  name                  = "web_ssh2"
  source_zones          = ["Untrust"]
  destination_zone      = "Untrust"
  source_addresses      = ["any"]
  destination_addresses = ["10.0.0.100"]
  service               = "service-tcp-222"
  sat_type              = "dynamic-ip-and-port"
  sat_address_type      = "interface-address"
  sat_interface         = "ethernet1/2"
  dat_address           = "10.0.1.102"
  dat_port              = "22"

  depends_on = ["panos_zone.untrust", "panos_ethernet_interface.eth2", "panos_service_object.service_tcp_222"]
}

resource "panos_nat_policy" "nat_rule_for_web_http2" {
  name                  = "web_http2"
  source_zones          = ["Untrust"]
  destination_zone      = "Untrust"
  source_addresses      = ["any"]
  destination_addresses = ["10.0.0.100"]
  service               = "http-81"
  sat_type              = "dynamic-ip-and-port"
  sat_address_type      = "interface-address"
  sat_interface         = "ethernet1/2"
  dat_address           = "10.0.1.102"
  dat_port              = "80"

  depends_on = ["panos_zone.untrust", "panos_ethernet_interface.eth2", "panos_service_object.http-81"]
}

#Create security rules
resource "panos_security_policies" "security_rules" {
  rule {
    name                  = "web traffic"
    source_zones          = ["Untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Trust"]
    destination_addresses = ["any"]
    applications          = ["web-browsing"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "ssh traffic"
    source_zones          = ["Untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Trust"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["service-tcp-221"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "allow all out"
    source_zones          = ["Trust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Untrust"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "web traffic 2"
    source_zones          = ["Untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Trust"]
    destination_addresses = ["any"]
    applications          = ["web-browsing"]
    services              = ["http-81"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "ssh traffic2"
    source_zones          = ["Untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Trust"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["service-tcp-222"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "log default deny"
    source_zones          = ["Untrust"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["Trust"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    log_start             = false
    log_end               = true
    action                = "deny"
  }

  depends_on = ["panos_zone.untrust", "panos_zone.trust", "panos_nat_policy.outbound_nat",
    "panos_nat_policy.nat_rule_for_web_http",
    "panos_nat_policy.nat_rule_for_web_ssh",
    "panos_virtual_router.default_vr",
    "panos_service_object.http-81",
    "panos_service_object.service_tcp_221",
    "panos_service_object.service_tcp_222",
  ]
}

#Commit the changes to the firewall
resource "null_resource" "commit_fw" {
  triggers {
    version = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./commit.sh ${var.fw_ip}"

    #interpreter = ["/usr/bin/bash", "-c"]
    on_failure = "continue"
  }
}
