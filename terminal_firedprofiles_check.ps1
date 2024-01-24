Import-Module activedirectory

$profiles = Get-ChildItem -Directory -Path C:\Users | where {$_.Name -match "[A-Z]\.[A-Z]"}
$NonActualProfiles = @()
$FiredProfiles = @()

ForEach ($profile in $profiles){
try{ 
   $FiredProfile = (Get-ADUser –Identity $profile.Name -Properties Enabled,DisplayName |  where {$_.Enabled -eq $false} | Select-Object samaccountName).samaccountName 
   if ($FiredProfile){
      $FiredProfiles += $FiredProfile
   }
}
catch{
        $NonActualProfiles += $profile.Name
   }
}

#ForEach ($profile in $NonActualProfiles){
#    Write-Host($profile)
#}
#ForEach ($profile in $FiredProfiles){
#   Write-Host($profile)
#}
$users = ForEach ($proffile in $FiredProfiles){
   New-Object -TypeName PSObject -Property @{
    'UserName' = $proffile
    'FreeSpace' = "{0:N2} GB" -f ((gci –force c:\users\$proffile –Recurse -ErrorAction SilentlyContinue| measure Length -s).sum / 1Gb)
}
}

$SortedUsers = $users | Sort-Object -Property FreeSpace -Descending

$firedemailbody = ForEach ($User in $SortedUsers){
   $username = $User.UserName
   $freespace = $User.FreeSpace
   "$username - $freespace<br>"
}

$NonActualEmailBody = ForEach($User in $NonActualProfiles){
"$user<br>"
}

$emailbody = "<h3>Данные пользователи находятся в статусе уволенных:</h3>" + $firedemailbody + "<h3>Данных пользователей нет в AD, но профили существуют (необходимо проверить вручную):</h3>" + $NonActualEmailBody

$smtpUsername = "test@mail.com"
$smtpPassword = ConvertTo-SecureString -String "1" -AsPlainText -Force
$smtpCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $smtpUsername, $smtpPassword

$MailMessage = @{
SmtpServer = "test@mail.com" 
To = "test@mail.com" 
From = "test@mail.com" 
Subject = "[1_W] 'Мертвые души' на терминальнике rlspb-ts2" 
Body = "$emailbody" 
Encoding = "UTF8"
BodyAsHtml = $true
Credential = $smtpCredential
}

Send-MailMessage @MailMessage