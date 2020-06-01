$username = "ansible_user"
$password = ConvertTo-SecureString "Password" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)


Install-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature
try{
    $defaultWeb = Get-Website "Defaule Web Site"
    if (!($defaultWeb -eq $null)){
        Remove-Website "Defaule Web Site" -ErrorAction Continue -WarningAction Continue
    }
}catch{
}

try{
    $tempFolder = Get-Item -Path "C:\" -Name "temp" -ItemType "directory"
    if (($tempFolder -eq $null)){
        New-Item -Path "c:\" -Name "temp" -ItemType "directory"
    }
}catch{
}

try{
    $siteFoler = Get-Item -Path "C:\Inetpub\wwwroot" -Name "HelloWorld" -ItemType "directory"
    if (($siteFoler -eq $null)){
        New-Item -Path -Path "C:\Inetpub\wwwroot" -Name "HelloWorld" -ItemType "directory"
    }
}catch{
}

try{
    $drive = Get-PSDrive -Name J -PSProvider FileSystem
    if (($drive -eq $null)){
        New-PSDrive -Name J -PSProvider FileSystem -Root \\10.140.0.2\Temp -Credential $creds -Persist
    }
}catch{
}

Copy-Item -Path J:\HelloWorld.zip -Destination C:\temp\HelloWorld.zip

Expand-Archive -LiteralPath C:\temp\HelloWorld.zip -DestinationPath C:\Inetpub\Wwwroot\HelloWorld -Force

New-Website -Name "Ansible Test Site" -Port 80 -PhysicalPath C:\inetpub\wwwroot\HelloWorld -Force
