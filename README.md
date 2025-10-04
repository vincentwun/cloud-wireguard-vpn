 # Cloud-WireGuard-VPN

 A simple, reusable Terraform-based solution to deploy WireGuard VPN servers on Azure and GCP. This repository provides:
 - Infrastructure as code for cloud VPN servers
 - Automated client configuration templates
 - Step-by-step deployment guides

 ---
 ## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
 - Active Azure and/or GCP account with billing enabled

 ---
 ## Quick Start

 1. Clone the repository:
	 ```bash
	 git clone https://github.com/vincentwun/cloud-wireguard-vpn.git
	 cd cloud-wireguard-vpn
	 ```
 2. Install required tools
	 ```bash
		./install.sh
	 ```
 3. Select your cloud provider:
	 ```bash
	 # Azure
	 cd azure

	 # GCP
	 cd gcp
	 ```
 4. Deploy infrastructure:
	 ```bash
	 terraform init
	 terraform plan -out=tfplan
	 terraform apply tfplan
	 ```
 5. Retrieve generated client configurations:
	 ```bash
	 ls client-configs/
	 ```

 ---
 ## Cleanup

 ```bash
 terraform destroy
 ```