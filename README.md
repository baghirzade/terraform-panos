<a name="readme-top"></a>
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/baghirzade/terraform-panos">
    <img src="images/main.png" alt="Logo" width="500" height="300">
  </a>

  <h3 align="center">Terraform for Palo Alto Networks PANOS</h3>

  <p align="center">
    An awesome Terraform provider to fastest configure ipsec in Palo alto Firewall!
    <br />
    <a href="https://github.com/baghirzade/terraform-panos"><strong>Explore the docs »</strong></a>
    <br />
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#terraform-installation">Terraform Installation</a></li>
      </ul>
    </li>
    <li><a href="#get-your-palo-alto-firewall-api-key">Get Your Palo Alto Firewall API Key</a></li>
    <li><a href="#starting-to-automate">Starting to automate</a></li>
    <li><a href="#reference-link">Reference link</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

This project was created to make the work of network administrators faster and more convenient. I hope Palo alto automation with Terraform will be a more useful and affordable project for you. It currently only covers each step from A to Z for setting up ipsec configuration. I will further expand the project and add the following configurations:

* U-Turn NAT :rocket:
* Vulnerability Protection :rocket:
* URL Filtering :rocket:
* and etc. :rocket:

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

This section should list any major frameworks/libraries used to bootstrap project. Leave any add-ons/plugins for the acknowledgements section. You need to install followings:

[![Windows 10][windows-shield]][windows-url] <br>
[![Terraform][terraform-shield]][terraform-url] <br>
[![Chocolatey][chocolatey-shield]][chocolatey-url] <br>
[![PANOS][panos-shield]][panos-url] <br>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

İf you are ready we can start now. First, let's start by downloading and installing the necessary programs.

### Prerequisites

You need to use the Chocolatey software and how to install it. Open the Windows PowerShell and run following command:
* install Chocolatey
  ```sh
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  ```

### Terraform Installation

_Below is an command of how you can instruct your audience on installing and setting up Terraform._

1. Get info at [https://developer.hashicorp.com](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. Open PowerShell and run following command
   ```sh
   choco install terraform
   ```
3. Verify the installation
   ```sh
   terraform -help
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Get Your Palo Alto Firewall API Key

1. Get info at [https://docs.paloaltonetworks.com](https://docs.paloaltonetworks.com/pan-os/10-2/pan-os-panorama-api/get-started-with-the-pan-os-xml-api/get-your-api-key)
2. Open your browser and change firewall field to ip address of firewall, username and password then go to link
   ```sh
   https://<firewall>/api/?type=keygen&user=<username>&password=<password>
   ```
3. If you want use curl or [Postman](https://www.postman.com/)
   ```sh
   curl -k -X GET 'https://<firewall>/api/?type=keygen&user=<username>&password=<password>'
   ```
4. Copy your API key for using in terraform code

### Starting to automate

1. Create credentials JSON file and copy following code and change API key field
   ```sh
   {
    "hostname": "10.4.4.200",
    "api_key": "LUFRPT1FK2x1YsfewewdFSEWESGJMazJHSlpYS2FRMkxwZkk9Z1hVTmh4Y3l3VjYreC9KeU5NNFUycm5hajhqOGtWQ2JMZHd4M3N2VTFnSlBFQUxJeGo1ZGJjcHl6N1BLSDFLTA==",
    "timeout": 10,
    "verify_certificate": false
   }
   ```
2. Create main terraform file and copy following code and change what you want for example local ip, peer ip, zone name, virtual route name and etc.
   ```sh
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
   ```
4. Run this command for installing panos library
   ```sh
   terraform init
   ```
5. Before apply configuration to Palo Alto Firewall test the code following command
   ```sh
   terraform plan
   ```
6. Finally, apply configuration this command
   ```sh
   terraform apply
   ```

# Note: Before doing all these operations, if you are working in a production environment, be sure to take the configuration backup or snapshot.

<!-- Reference link -->
## Reference link

[Terraform for PAN-OS](https://pan.dev/terraform/docs/panos/) <br>
[Terraform Provider panos](https://registry.terraform.io/providers/PaloAltoNetworks/panos/latest/docs) <br>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



[panos-shield]: https://img.shields.io/badge/PANOS-v10.0.0%2B-yellow?style=for-the-badge
[panos-url]: https://docs.paloaltonetworks.com/pan-os/10-1/pan-os-admin/getting-started/integrate-the-firewall-into-your-management-network/perform-initial-configuration

[chocolatey-shield]: https://img.shields.io/badge/Chocolatey-PowerShell%20v2%2B-blue?style=for-the-badge
[chocolatey-url]: https://chocolatey.org/install

[terraform-shield]: https://img.shields.io/badge/terraform-1.11.1-blueviolet?style=for-the-badge
[terraform-url]: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

[windows-shield]: https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white
[windows-url]: https://www.microsoft.com/en-us/software-download/windows10

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/fazilbaghirzade
