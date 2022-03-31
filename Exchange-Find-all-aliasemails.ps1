#Path for Final output
$output = 'C:\Temp\aliasexport.csv'


#This part pulls the secondary smtps from O365
Get-Recipient | Select-Object @{Name="EmailAddresses";Expression={($_.EmailAddresses | Where-Object {$_ -clike "smtp*"} | ForEach-Object {$_ -replace "smtp:",""}) -join "`n"}} | Export-Csv -path $output -NoTypeInformation
(Get-Content $output | Select-Object -Skip 1) | Set-Content $output

#This part will remove the empty rows from csv
 $objs = Import-Csv -Path $output 
 $properties = ($objs | Get-Member -MemberType NoteProperty).Name
 $exclude = @()
 foreach($property in $properties){if(($objs.$property | where-object{$_}).count -eq 0){$exclude += $property } }
 $txtoutput = Import-Csv $output
 $objs | Select-Object -Property * -ExcludeProperty $exclude | Export-Csv -NoTypeInformation -Path $output

 #This part will create separate rows for each email addresse
 $txtoutput | Export-csv C:\Temp\o365-1-0-0.txt -NoTypeInformation 
 (Get-Content C:\Temp\o365-1-0-0.txt -Encoding UTF8) | ForEach-Object {$_ -replace '"',''} | Out-File $output -Encoding UTF8
