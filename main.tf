terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "1.11.1"
    }
  }
}

provider "panos" {
    hostname = "10.4.4.200"
    json_config_file = "panos-creds.json"
}

resource "panos_zone" "partnerZone" {
    name = "partnerZone"
    mode = "layer3"
    interfaces = ["tunnel.200"]

    lifecycle {
        create_before_destroy = true
    }
}

resource "panos_tunnel_interface" "PartnerTunnelInterface" {
    name = "tunnel.200"
    comment = "Partner Tunnel Interface"
    lifecycle {
        create_before_destroy = true
    }
}

resource "panos_virtual_router" "default_vr" {
  name       = "default"
  interfaces = ["tunnel.200"]
}

resource "panos_ike_crypto_profile" "IKEv2_AES256_DH14_86400s" {
  name                    = "IKEv2_AES256_DH14_86400s"
  dh_groups               = ["group14"]
  authentications         = ["sha256"]
  encryptions             = ["aes-256-cbc"]
  lifetime_value          = 1
  lifetime_type           = "days"
}

resource "panos_ike_gateway" "partnerIKE" {
  name                     = "partnerIKE"
  interface                = "ethernet1/1"
  version                  = "ikev2"
  auth_type                = "pre-shared-key" 
  pre_shared_key           = "STRONG_KEY_HERE"
  local_id_type            = "ipaddr"
  local_id_value           = "1.1.1.1"
  peer_ip_type             = "ip"
  peer_ip_value            = "9.9.9.9"
  ikev2_crypto_profile     = panos_ike_crypto_profile.IKEv2_AES256_DH14_86400s.name
}

resource "panos_ipsec_crypto_profile" "IPSEC_AES256_DH14_86400s" {
  name            = "IPSEC_AES256_DH14_86400s"
  authentications = ["sha256"]
  encryptions     = ["aes-256-cbc"]
  dh_group        = "group14"
  lifetime_type   = "seconds"
  lifetime_value  = 3600
}

resource "panos_ipsec_tunnel" "partnerIPSEC" {
  name                    = "partnerIPSEC"
  tunnel_interface        = panos_tunnel_interface.PartnerTunnelInterface.name
  ak_ike_gateway          = panos_ike_gateway.partnerIKE.name
  ak_ipsec_crypto_profile = panos_ipsec_crypto_profile.IPSEC_AES256_DH14_86400s.name
}

# Proxy IDs
resource "panos_ipsec_tunnel_proxy_id_ipv4" "PartnerProxyID1" {
  ipsec_tunnel = panos_ipsec_tunnel.partnerIPSEC.name
  name         = "Tunnel1"
  local        = "7.7.7.7/32"
  remote       = "8.8.8.8/32"
  protocol_any = true
}

# Policy rule
resource "panos_security_policy" "example" {
    rule {
        name = "allow ipsec traffic"
        audit_comment = "Initial config"
        source_zones = ["Inside"]
        source_addresses = ["any"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["partnerZone"]
        destination_addresses = ["any"]
        applications = ["any"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
    lifecycle {
        create_before_destroy = true
    }
}
