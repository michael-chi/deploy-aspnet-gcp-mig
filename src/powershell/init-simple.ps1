$username = "ansible_user"
$password = ConvertTo-SecureString "Passow" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

try{
    $drive = Get-PSDrive -Name j -PSProvider FileSystem
    if (($drive -eq $null)){
        New-PSDrive -Name j -PSProvider FileSystem -Root \\10.140.0.2\Temp -Credential $creds -Persist
    }
}catch{
}

mkdir C:\temp
mkdir C:\Inetpub\wwwroot\HelloWorld
copy j:\HelloWorld.zip c:\temp\HelloWorld.zip

Expand-Archive -LiteralPath C:\temp\HelloWorld.zip -DestinationPath C:\Inetpub\Wwwroot\HelloWorld -Force
Remove-Website "Default Web Site" -ErrorAction Continue -WarningAction Continue
New-Website -Name "Ansible Test Site" -Port 80 -PhysicalPath C:\inetpub\wwwroot\HelloWorld -Force
Start-Website -Name "Ansible Test Site"