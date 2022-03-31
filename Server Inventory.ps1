<#
.DESCRIPTION - Auditing Script - Construction Phase !!!
- Create folder called 'Audit' under C:\Temp
- Create text file called 'Servers.txt' and place in newly created C:\Temp\Audit folder
- Servers.txt should contain a list of server names you wish to audit\target
.Author MCD
#>

########## Output Folder ##########
$outputFolderName = 'Audit ' + $(Get-Date -f dd-MM-yyyy)
$outputpath = "C:\temp\Audit\$outputFolderName"
If(!(test-path $outputpath)) {
    New-Item -ItemType Directory -Force -Path $outputpath | out-null
}
                
########## Prompt 1 ##########
Add-Type -AssemblyName Microsoft.VisualBasic
$ClientName = [Microsoft.VisualBasic.Interaction]::InputBox('Please enter Client\Customer name i.e. Contoso Ltd', 'User')
Start-Sleep -s 2

#Manual Input File Location
$computers = Get-Content -path c:\temp\audit\Servers.txt
                
########## Create an Empty Array ##########
$report = @()

########## Main Start ##########
Foreach ($Computer in $Computers) {
    
    ########## WMI/Ping Test ##########
    $wmi = gwmi win32_bios -ComputerName $computer -ErrorAction SilentlyContinue
    $Ping = Test-Connection -ComputerName $computer -Quiet -count 2
        
    ########## Main If Else Loop ##########
    if ($wmi) {
        $WMIResult = 'Server IS Contactable' 
                
        ########## HW/Serial No/Bios ##########
        $Bios = Get-WmiObject -Class win32_bios -ComputerName $Computer
        $systemBios = $Bios.serialnumber
        $Hardware = Get-WmiObject -Class Win32_computerSystem -ComputerName $Computer
                        
        ########## OS Version/Last Reboot ##########
        $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
        $lastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)
        $uptimeDays = ((get-date) - ($os.ConvertToDateTime($os.lastbootuptime))).Days
        
        ########## Network Info ##########
        $Networks = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object {$_.IPEnabled}
        $IPAddress  = ($Networks.IpAddress | where {$_ -notmatch ":"}) -join "`n"
        $MACAddress  = ($Networks.MACAddress) -join "`n"
        $IpSubnet  = ($Networks.IpSubnet | ? { $_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' }) -join "`n"
        $DefaultGateway = ($Networks.DefaultIPGateway) -join "`n"
        
        ########## LastLogon/Created ##########
        $LastLogonDate = Get-ADComputer $computer -Properties * | select -ExpandProperty LastLogonDate 
        $Created = Get-ADComputer $computer -Properties * | select -ExpandProperty Created 
        
        ########## OUTPUT ##########
        $tempreport  = New-Object -TypeName PSObject
        $tempreport | Add-Member -MemberType NoteProperty -Name ServerName -Value $Computer.ToUpper()
        $tempreport | Add-Member -MemberType NoteProperty -Name Client_Customer -Value $ClientName.ToUpper()
        $tempreport | Add-Member -MemberType NoteProperty -Name WMI_Connection -Value $WMIResult
        $tempreport | Add-Member -MemberType NoteProperty -Name Pingable -Value $Ping
        $tempreport | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Hardware.Manufacturer
        $tempreport | Add-Member -MemberType NoteProperty -Name Model -Value $Hardware.Model
        $tempreport | Add-Member -MemberType NoteProperty -Name Operating_System -Value $OS.Caption
        $tempreport | Add-Member -MemberType NoteProperty -Name IP_Address -Value $IPAddress
        $tempreport | Add-Member -MemberType NoteProperty -Name Default_Gateway -Value $DefaultGateway
        $tempreport | Add-Member -MemberType NoteProperty -Name MAC_Address -Value $MACAddress
        $tempreport | Add-Member -MemberType NoteProperty -Name IpSubnet -Value $IpSubnet
        $tempreport | Add-Member -MemberType NoteProperty -Name Last_ReBoot -Value $lastboot
        $tempreport | Add-Member -MemberType NoteProperty -Name Uptime_Days -Value $uptimeDays
        $tempreport | Add-Member -MemberType NoteProperty -Name Last_Logon -Value $LastLogonDate
        $tempreport | Add-Member -MemberType NoteProperty -Name Created -Value $Created
        $tempreport | Add-Member -MemberType NoteProperty -Name Serial_Number -Value $systemBios
            
        $report += $tempreport
                
    }
    else {
    
        $WMIResult = 'Server NOT Contactable'
                
        $tempreport = New-Object PSObject  
        $tempreport | Add-Member -MemberType NoteProperty -Name ServerName -Value $Computer.ToUpper()
        $tempreport | Add-Member -MemberType NoteProperty -Name Client_Customer -Value $ClientName.ToUpper()
        $tempreport | Add-Member -MemberType NoteProperty -Name WMI_Connection -Value $WMIResult
        $tempreport | Add-Member -MemberType NoteProperty -Name Pingable -Value $Ping
        $tempreport | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Model -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Operating_System -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name IP_Address -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Default_Gateway -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name MAC_Address -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name IpSubnet -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Last_ReBoot -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Uptime_Days -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Last_Logon -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Created -Value $null
        $tempreport | Add-Member -MemberType NoteProperty -Name Serial_Number -Value $null
            
        $report += $tempreport  
    }
}

########## EXPORT TO CSV ##########
$CSVFileName = $ClientName + ' Server Inventory ' + $(Get-Date -f dd-MM-yyyy) + '.csv'
$report | Export-Csv "$outputpath\$CSVFileName" -NoTypeInformation