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


## Preparation

In this demo, I have a Windows Server that shares its folder which contains a HelloWorld.zip that holds my WebSite bits. In order to have my auto-provisioned machines access to the share folder, I must create `ansible_user` in my file server with same password I set in my Windows hosts.

## Steps

Create a Storage Bucket and upload a sample ASP.Net application zip file called HelloWorld.zip

Grant Service Account or your Google Account Storage Viewer permission

Create a folder called playerbooks and create a new file called `win-iis.yaml` with below content

Your folder structure should look like this now.

    |-- gcp
        |-- gce.ini
        |-- gcp.py
        |-- [key-file.json]
        |-- group_vars
            |-- tag_win-iis
        |-- playbooks
            |-- win-iis.yaml

win-iis.yaml should have below content.

```yaml
- hosts: all
  tasks:
    - name: Remove Default Web Site
      win_iis_website:
        name: "Default Web Site"
        state: absent
    - name: Create temp folder
      win_file:
        path: C:\temp
        state: directory
    - name: Create web site directory
      win_file:
        path: C:\inetpub\wwwroot\HelloWorld
        state: directory
    - name: Copy Remote File
      win_copy:
        src: \\<REMOTE FILESHARE IP>\Temp\HelloWorld.zip
        dest: C:\temp\
        remote_src: True
      vars:
        ansible_become: yes
        ansible_become_method: runas
        ansible_become_user: ansible_user
        ansible_become_password: Very-Secure-Password
        ansible_remote_tmp: 'c:\Temp'
    - name: Extract to C:\inetpub\wwwroot\HelloWorld
      win_unzip:
        src: C:\temp\HelloWorld.zip
        dest: C:\inetpub\wwwroot\HelloWorld
        # recurse: yes
        # remote_src: yes
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
        port: 80
        physical_path: C:\inetpub\wwwroot\HelloWorld
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
