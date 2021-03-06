## Overview
---
In order to have our ASP.Net applications able to talk with Ansible, we need to first setup our Windows host. Ansible leverage Winrm to talk with managed hosts which is not installed and enabled by default.

In this section, I will describe steps required to setup WinRM environment and make this environment a base image for further Managed Instance Group dpeloyments.

In later section, I will demonstrate using Ansible to configure ASP.Net IIS websites, however, in real scenario, you may want to configure and setup required Windows Features and make it part of your base image instead of install those features on the fly to reduce time to serve.

## What are we building ?

We will be building a Windows based image with below features enabled

- WinRM

- Instace Template


## Steps
---

### Machine setup

Create a Windows machines on GCP then RDP into the machine.

-   Create a local user if your machine will not join Windows AD. Add this newly created user to `Administrators` group and note its passeword. Ansible will be using this user to talk our Windows hosts. In my demo I named this user `ansible_user`

-   [Optional]Install [Python](https://www.python.org/downloads/windows/) version 3.7 or below if you will use GCP extensions in playbooks such as `gs_storage`

-   Now we want to install WinRM feature to the machine. WinRM is used by Ansible to talk to Windows hosts we want to manage.

-   We also want to setup basic authentication since our machines will not be joining Windows AD.

[Ansible document](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#upgrading-powershell-and-net-framework)provides detailed instruction to setup Windows hosts, below is a summary of Powershell coded from official Andible document.

<!-- 
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
$file = "$env:temp\Upgrade-PowerShell.ps1"
$username = "ansible_user"
$password = "Super-Safe-Password"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Version can be 3.0, 4.0 or 5.1
&$file -Version 5.1 -Username $username -Password $password -Verbose

Set-ExecutionPolicy -ExecutionPolicy Restricted -Force

$reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue
 -->

```powershell

# Setup WinRM
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted 
powershell.exe -ExecutionPolicy ByPass -File $file

# winrm enumerate winrm/config/Listener
# $trumbprint="329EB46A0D76C646CB0C69587DDB5C5A0CA2A550"
# $selector_set = @{
#     Address = "*"
#     Transport = "HTTPS"
# }
# $value_set = @{
#     CertificateThumbprint = $trumbprint
# }
# New-WSManInstance -ResourceURI "winrm/config/Listener" -SelectorSet $selector_set -ValueSet $value_set

winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
```

-   Once completed, configure and install other application dependencies and run `GCESyspre` when finished. This will automatically initialize and shutdown your machine.

-   Go back to GCP console, optionally delete machine and keep boot disk, create an Image from that Disk, then create an Instance Template from that Image. 
    - In order to have better manage our machines, we add a network tag `win-iis` to the Instance Template, so that every machines provisioned based on this template shares same network tag, later we will use this tag to tell Ansible which machines to deploy new configurations.

-   To have Ansible be able to talk to our Windows hosts and managed IIS websites, below tasks are required in Windows Server

    - Install `Web-Server` Role, ensure `WebAdministration` Powershell module is installed
    
    - Ensure Firewall on Windows Machines allow HTTP and HTTPS traffic

### Create Instance Template

Once we have everything setup and configured in the Windows machine, I can now make it an Instance Template.

The Template must have below configuration

|Configuration|Value|Comments|
|:--:|:--:|:--:|
|Network tag|`win-iis`|My Ansible playbooks apply to machines with this tag only|
|`windows-startup-script-url`|`gs://my-bucket/init.ps1`|Newly provisioned machines use this script to initialize itself|

A very simple Powershell script which does what Ansible playbook does has been created as a [sample](./src/powershell/init.ps1)

#### Next Steps

[Setup Ansible Workstation to manage Managed Instnace Group](./setup-ubuntu-ansible-server.md)

