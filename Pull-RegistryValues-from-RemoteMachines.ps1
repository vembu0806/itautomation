

########## Output Folder ##########
$outputFolderName = 'Volatile' + $(Get-Date -f dd-MM-yyyy)
$outputpath = "C:\temp\Volatile\$outputFolderName"
If(!(test-path $outputpath)) {
    New-Item -ItemType Directory -Force -Path $outputpath | out-null
}
                
########## Prompt 1 ##########


#Manual Input File Location
$computers = Get-Content -path \\WIN-0L6Q84RQV4D\C$\Temp\Servers.txt     
      
########## Create an Empty Array ##########
$report = @()

$VE = {
Get-ChildItem Registry::\HKEY_USERS |
Where-Object { Test-Path "$($_.pspath)\Volatile Environment" } |
ForEach-Object { (Get-ItemProperty "$($_.pspath)\Volatile Environment") }
}


########## Main Start ##########
Foreach ($Computer in $Computers) {
    
                 
        
        $Volatile  =  Invoke-command -computer $Computer -ScriptBlock $VE
       
        
        ########## OUTPUT ##########
        $tempreport  = New-Object -TypeName PSObject
        
        $tempreport | Add-Member -MemberType NoteProperty -Name 'Registry Details' -Value $Volatile
        
            
        $report += $tempreport
                
    }
   

########## EXPORT TO TXT ##########
$CSVFileName = $ClientName + ' Server Inventory ' + $(Get-Date -f dd-MM-yyyy) + '.txt'
$report | Export-Csv "$outputpath\$CSVFileName" -NoTypeInformation
$output = 'C:\Temp\Volatile-export1.txt'

(Get-Content  "$outputpath\$CSVFileName" -Encoding UTF8) | ForEach-Object {$_ -replace ';',"`r`n"} |ForEach-Object {$_ -replace '@',"`r`n"}| ForEach-Object {$_ -replace '{',"`r`n"} |ForEach-Object {$_ -replace '}',"`r`n"} |ForEach-Object {$_ -replace '"',"`r`n"}| Out-File $output -Encoding UTF8
