## Overview
---
We will be creating an Ansible environment on Ubuntu to manage our Windows machines and deploy ASP.Net websites

## What are we building ?

We will be building an Ubunut 18.04 TLS machines, and install Ansible 2.9 on it.

- An Ubuntu 18.04 TLS machine

- Install Ansible 2.9

## How are we solving

Since Managed Instance Group provision new machines when required, and delete machines when scaling down. We need a mechanism that recognize newly created machines as well as aware of those deleted machines.

Ansible provides a concept of `Dynamic Inventory` which allows you to dynamically collect resources from different cloud providers including Google Cloud Platform. We will leverage this feature to collect machines that need to deploy new configurations on the fly and applies playbooks to them.

## Steps
---

### Machine setup

Create a Ubuntu 18.04 TLS machine on GCP console, once provisioned, SSH into the machine and execute below commands to setup Ansible environment.

```bash
# Add repository and install Ansible and its dependencies
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update

sudo apt-get install -y ansible
sudo apt-get install -y python-pip

pip install pywinrm
pip install apache-libcloud
pip install requests google-auth

# Create our working directory
mkdir gcp
cd gcp

mkdir inventory
cd inventory

wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/gce.ini
wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/gce.py

# Make GCE.PY executable
sudo chmod +x gce.py
```

### Dynamic Inventory

To manage Cloud Resources efficiently, Ansible introduces [Dynamic Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) which allows Ansible to track fetch resources provisioned in different environemnt such as Google Cloud Platform, so that you don't have to keep tracking which resources been provisioned or deleted.

There are two ways to connect with external inventory: Inventory PlugIns or Inventory Scripts

Inventory Plugin is the Ansiblee recommended way to manage external inventory which ensure backward compatibility. While managing Google Cloud Platform, it is recommended to use [dynamic script](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html).


### Dynamic Inventory Prepration

To allow Ansible manage GCP resources, first we create a Service Account, provide it with required permissions. In this lab since we are only to manage my Compute Engine Instances, I simply uses existing Compute Engine default service account instead.

For security purpose, it is recommended to create a Service Account for Ansible and grant permissions required.

Once created, go to IAM console and download JSON key files to Ansible workstation.

#### Inventory Script

Download `gce.py` and `gce.ini`

```bash
mkdir gcp
cd gcp

wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/gce.ini
wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/gce.py
```

Update `gce.ini` with GCP service account, key files, project id...etc

```ini
[gce]
gce_service_account_email_address =[SERVICE ACCOUNT]@developer.gserviceaccount.com
gce_service_account_pem_file_path =[SERVICE ACCOUNT KEY FILE PATH]
gce_project_id =[GCP PROJECT ID]
gce_zone = [OPTIONAL]

# Filter inventory based on state. Leave undefined to return instances regardless of state.
instance_states = RUNNING,PROVISIONING

# In my scenario, I only want to work with my Windows IIS machines
# instance_tags = win-iis

[inventory]
# The 'inventory_ip_type' parameter specifies whether 'ansible_ssh_host' should
# contain the instance internal or external address. Values may be either
# 'internal' or 'external'. If 'external' is specified but no external instance
# address exists, the internal address will be used.
# The INVENTORY_IP_TYPE environment variable will override this value.
inventory_ip_type =internal

[cache]
# directory in which cache should be created
cache_path = ~/.ansible/tmp
# The number of seconds a cache file is considered valid. After this many
# seconds, a new API call will be made, and the cache file will be updated.
# To disable the cache, set this value to 0
cache_max_age = 300
```

Once created, execute below command to tell Ansible where our GCP enviornment configurations are

```bash
GCE_INI_PATH=[PATH TO GCE.INI]
```

Now we want to configure connection parameters so that Ansible knows how to talk with my Windows machines
>Note that group variable file name shoud be `tag_<tag-name>`, in my case it's `tag_win-iis`

```bash
mkdir group_vars

cat >>group_vars/tag_win-iis<<EOF
ansible_user: <YOUR WINDOWS LOCAL USER ID HERE>
ansible_password: Really-Strong-Password
ansible_port: 5986
ansible_connection: winrm
ansible_winrm_server_cert_validation: ignore
EOF
```

Now we can verify if Ansible is able to connect to our Windows hosts now

```bash
ansible -i gce.py tag_win-iis -m win_ping

# ansible-group-20200529-001-r76g | SUCCESS => {
#     "changed": false, 
#     "ping": "pong"
# }
```

Your folder structure should look like this now.

    |-- gcp
        |-- gce.ini
        |-- gcp.py
        |-- [key-file.json]
        |-- group_vars
            |-- tag_win-iis

 #### Next Steps

 [Working with Playbooks](./setup-playbooks.md)