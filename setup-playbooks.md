## Overview

Upon finished pervious steps, we are now have every thing we need ready.

We have Managed Instance Group that scales when required, those machines pull latest version via start scripts. 
We also have Ansible setup to manage our automatically created machines without having to tracking machine provisioning and deletion.

In this section, we want to create Ansible playbooks to deploy new version of codes to our managed instance group.

## What are we building ?

We will be creating a playbook which does the following

-   Ensure `c:\inetpub\wwwroot\mydemo` folder exists
-   Ensure Web-Server Windows Feature and its subsequence features installed
-   Ensure a Web Site with physical path set to `c:\inetpub\wwwroot\mydemo` exists, if no, create a new one.

## Steps

Create a folder called playerbooks and create a new file called `win-iis.yaml` with below content


```yaml
- hosts: all 
  tasks:
    - name: Create directory structure
      win_file:
        path: C:\inetpub\wwwroot\mydemo
        state: directory
    - name: Install Web Server
      win_feature:
        name: "Web-Server"
        state: present
        restart: no
        include_sub_features: yes
        include_management_tools: no
    - name: create new website
      win_iis_website:
        name: "Ansible Test Site"
        state: started
        port: 8081
        physical_path: C:\inetpub\wwwroot\mydemo
```

Once created, go back to our inventory folder and execute below command

```bash
ansible-playbook -i gce.py playbooks/win-iis.yaml
```

You should see similar outputs
```
PLAY [all] *******************************************************************************************************************************************************************
TASK [Gathering Facts] *******************************************************************************************************************************************************
ok: [ansible-group-20200529-001-r76g]
TASK [Create directory structure] ********************************************************************************************************************************************
ok: [ansible-group-20200529-001-r76g]
TASK [Install Web Server] ****************************************************************************************************************************************************
ok: [ansible-group-20200529-001-r76g]
TASK [create new website] ****************************************************************************************************************************************************
ok: [ansible-group-20200529-001-r76g]
PLAY RECAP *******************************************************************************************************************************************************************
ansible-group-20200529-001-r76g : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
