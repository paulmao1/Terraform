# Terraform + Cloud-init

This repository uses terraform to build virtual_machine_scale_set and configures it with cloud-init.


It will use the following feature:

* Template for cloud-init configure
* Module for Load Balance
* Workspace for different roles
* Plugin for Ansible Dynamic Invertory



Supported platform:
* Ubuntu16.0.4
* Ubuntu18.0.4
* Azure Cloud


## Usage

1. Clone the repository and cd into it

```
git clone https://github.com/paulmao1/Terraform.git
cd Terraform
```

2. Add environment variable for Azure account and export them:
```
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

4. Run the scripts follwing the [instructions][1]

5. You can find the Ansinle Dynamic Invertory [here][2]

[1]:https://github.com/paulmao1/Terraform/command.txt
[2]:https://github.com/nbering/terraform-provider-ansible

