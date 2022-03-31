#Clear-Host
#import module
Import-Module activedirectory

##add assembly for message box
Add-Type -AssemblyName PresentationFramework
##add assembly for forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function show_gui(){

    $global:form = new-object system.windows.forms.form
    $form.Text = 'New AD User'
    $form.Size = New-Object System.Drawing.Size(800,700)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;


    ##Define text label1
    $textLabel1 = New-Object “System.Windows.Forms.Label”;
    $textLabel1.Left = 50;
    $textLabel1.Top = 15;
    $textLabel1.Size = New-Object System.Drawing.Size(260,40)
    $textLabel1.Text = "Select An OU:";
    $textLabel1.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::BOLD)
    $form.Controls.Add($textLabel1);

     ##Define OU Button
    $ouButton = New-Object System.Windows.Forms.Button
    $ouButton.Location = New-Object System.Drawing.Point(350,15)
    $ouButton.Size = New-Object System.Drawing.Size(100,50)
    $ouButton.Text = 'Select An OU'
    $ouButton.Add_Click( {
    Function Show-FormOUSelector {
[void][reflection.assembly]::Load("mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[void][reflection.assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

[System.Windows.Forms.Application]::EnableVisualStyles()
$Imagelist1 = New-Object System.Windows.Forms.ImageList
$ErrorProviderOU = New-Object System.Windows.Forms.ErrorProvider
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
$script:SelectedOU = $null

Function Add-Node {
    Param (
        $selectedNode,
        $dname,
        $name,
        $ou
    )
    $newNode = New-Object System.Windows.Forms.TreeNode 
    $newNode.Name = $dname
    $newNode.Text = $name
    IF($ou -eq $false) {
        $newnode.ImageIndex = 1
        $newNode.SelectedImageIndex = 1
    }
    $selectedNode.Nodes.Add($newNode) | Out-Null
    If($dname -eq $strDomainDN){
        $newNode.ImageIndex = 2
        $newNode.SelectedImageIndex = 2
    }
    return $newNode
}

Function Get-NextLevel {
    Param (
        $selectedNode,
        $dn,
        $name,
        $OU
    )
  
        $OUs = Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel -SearchBase $dn    

    If ($OUs -eq $null) {
        $node = Add-Node $selectedNode $dn $name $OU
    }
        Else {
        $node = Add-Node $selectedNode $dn $name $OU
       
        $OUs | % {
            If ($_.ObjectClass -eq "organizationalUnit") {
                $OU = $true
            }
            else {
                $OU = $false
            }
            Get-NextLevel $node $_.distinguishedName $_.name $OU
        }
    }
}

Function Build-TreeView {
    if ($treeNodes) { 
        $Treeview.Nodes.remove($treeNodes)
        $FormOU.Refresh()
    }
   
    $treeNodes = $Treeview.Nodes[0]
        
    Get-NextLevel $treeNodes $strDomainDN $strDNSDomain

    $treeNodes.Expand()
    $treeNodes.FirstNode.Expand()
}

    Function Select-ChildNodes {
        Param (
            $node
        )
        $checkStatus = $node.Checked
        foreach ($n in $node.Nodes) {
            $n.checked = $checkstatus
            Select-ChildNodes($n)
        }
    }

    Function Select-ParentNode {
        Param (
            $node
        )
        $parent = $node.Parent
        if($parent -eq $null) {
            return
        }
        $parent.checked = $true
        foreach ($n in $parent.Nodes) {
            if(!$n.checked) {
                $parent.Checked = $false
                break
            } 
        }
        Select-ParentNode($parent)
    }

    Function Get-CheckedNodes {
        Param (
            $Nodes
        )
        $allChecked = $True
        foreach ($n in $Nodes) {
            if (!$n.Checked) {
                $allChecked = $false
                break
            }
        }
        foreach ($n in $Nodes) {
            if ($n.Nodes.Count -gt 0) {
                Get-CheckedNodes $n.Nodes
            }
            if ($n.Checked -and $n.Nodes.Count -eq 0) {
                Write-Output $n.Name
            }          
        }  
    }

    $FormEvent_Load = {
        Import-Module ActiveDirectory
        $objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
        $strDNSDomain = $objIPProperties.DomainName.toLower()
        $strDomainDN = $strDNSDomain.toString().split('.'); foreach ($strVal in $strDomainDN) {$strTemp += "dc=$strVal,"}; $strDomainDN = $strTemp.TrimEnd(",").toLower()
        Build-TreeView
    }

    $ButtonOK_Click = {
        if ($script:SelectedOU = Get-CheckedNodes $Treeview.Nodes) {
            $FormOU.close()
        }
        elseif (([System.Windows.Forms.MessageBox]::Show(
                    "You haven't selected anything.`nAre you sure you want to leave?",
                    "Oops!",'YesNo','Information')) -eq 'Yes') {$FormOU.Close()}
                    # Icons: Warning, Error, Information, None, Question # Buttons: YesNo, Ok
    }

    $ButtonCancel_Click = {
        $script:SelectedOU = $null
        $FormOU.close()
    }

    $Treeview_AfterCheck = {
        $Treeview.Remove_AfterCheck($Treeview_AfterCheck)
        Select-ChildNodes($_.node)
        Select-ParentNode($_.node)
        $Treeview.Add_AfterCheck($Treeview_AfterCheck)
    }

$Form_StateCorrection_Load = {
        $FormOU.WindowState = $InitialFormWindowState
}

$Form_Cleanup_FormClosed = {
    Try {       $ButtonOK.remove_Click($ButtonOK_Click)
    $FormOU.remove_Load($FormEvent_Load)
    $FormOU.remove_Load($Form_StateCorrection_Load)
    $FormOU.remove_FormClosed($Form_Cleanup_FormClosed)

}
Catch [Exception] {
        }
}

    $FormOU = New-Object System.Windows.Forms.Form
    $FormOU.Name = 'formChooseOU'
    $FormOU.StartPosition = 'CenterScreen'
    $FormOU.AcceptButton = $ButtonOK
    $FormOU.ClientSize = '342, 502'
    $FormOU.FormBorderStyle = 'FixedDialog'
    $FormOU.Icon = [System.Convert]::FromBase64String('
AAABAAkAICAQAAEABADoAgAAlgAAABgYEAABAAQA6AEAAH4DAAAQEBAAAQAEACgBAABmBQAAICAA
AAEACACoCAAAjgYAABgYAAABAAgAyAYAADYPAAAQEAAAAQAIAGgFAAD+FQAAICAAAAEAIACoEAAA
ZhsAABgYAAABACAAiAkAAA4sAAAQEAAAAQAgAGgEAACWNQAAKAAAACAAAABAAAAAAQAEAAAAAAAA
AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAIAAAACAgACAAAAAgACAAICAAACAgIAAwMDAAAAA
/wAA/wAAAP//AP8AAAD/AP8A//8AAP///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAiIAAAAAAAAAAAAAAAACIiIiHMAAAAAAAAAAAAAiI//iIiHcAAAAAAAAAAIiP//+IiIiH
dwAAAAAAiI//////iIiIiHhwAAAAAIj///////iIiIiHeHAAAACIj////4iIiIiIiIiHgAAAiIj/
iIiIiIj/iIiHeIcAAIiIiIiIiIiIiP+IiIeIcACIiHd3d3d3eIeI+IiHeIhwczMRMzd3czeIeI/4
iIiIcAczN3iIiIczeId4j4iHiHAACIiP///4i7OIh4iPiHiAAAAIiI//iIu7M4h3iP+HcAAAAAiI
iIi7u7u3iHiIiHAAAAAACIeP///4i7iHeIgAAAAAAAAAiI+IiLu7t3AAAAAAAAAAAACDMzMzMzM3
AAAAAAAAAAAAAAAAAAAACIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//////////////////////////////////////////
///////8f///wB///gAP//AAA/8AAAH/AAAAfwAAAB8AAAAPAAAABwAAAAEAAAABgAAAAeAAAAH4
AAAB/gAAAf+AAAP/8AAf//wAD////+f/////////////////////KAAAABgAAAAwAAAAAQAEAAAA
AAAgAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAIAAAACAgACAAAAAgACAAICAAACAgIAAwMDA
AAAA/wAA/wAAAP//AP8AAAD/AP8A//8AAP///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIiIAAAAAAAA
AAAIiIiIcAAAAAAAAIiI/4iIhwAAAAAIiP//+IiIh3gAAACI/////4iHiHeAAACIj//4iIiIeIiI
AACIiIiIiIiPiIh4iACIiId4iIiI+IiHiHCHczMzd3eIiPiHeIeDAzd4h3M3iI+Id4gAiIj//4iz
eIiPh4gAAIiIiIu7M3iIiHcAAACIiIiIizeIiIcAAAAAiI//iLt3gAAAAAAAAIhzMzMzMAAAAAAA
AAAAAAAAdwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8A////AP///wD///8A////AP///wD/
w/8A/gH/APAA/wCAAD8AAAAfAAAADwAAAAMAAAABAAAAAAAAAAAAwAAAAPAAAAD8AAAA/wAHAP/A
BwD///MA////AP///wAoAAAAEAAAACAAAAABAAQAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAICAgADAwMAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA
////AAAzMzMzMzMAAHd3d3MzMwAAd3d3czMzAACPiIiIiIMAAI+IiIiIgwAAj4iIiIiDAACPiIiI
iIMAAI+IiIiIgwAAj4iIh3eDAACPj///94MAAI+P///3gwAAj4////eDAACPiIiId4MAAHd3d3Mz
MwAAd3d3d3d3AAAAAAAAAAAAwAMAAMADAADAAwAAwAMAAMADAADAAwAAwAMAAMADAADAAwAAwAMA
AMADAADAAwAAwAMAAMADAADAAwAA//8AACgAAAAgAAAAQAAAAAEACAAAAAAAAAQAAAAAAAAAAAAA
AAEAAAABAAAAAAAAEj1BABlFSgAZSlIAIUpNAC5dXgAwV1kAMWRtAD9jaQA8aXoAVWttAFhpaQBK
bnQATH5/AF16ewAAaZMACmuTAAl0mgA/eIIAHXqgACp+owBNd4EAS32LAGF9gAAShJgALouZADyG
mQAKh6kAE4ujACWNqAA/jaMAMourAC6SrgAumbIAOJayAEmDjABEgpMAS4eQAFCHkABSiZIAVZOd
AFmUngBhh4kAaIeMAGmMjQBnlZsAaZmbAHWUkwB7lJMAcJyfAHWdnwBQkKQAX5ujAEKfugBqnaEA
UKK7AF2puwBpoaUAYqSqAGmlqQBvqq4AfaOsAHWprQB4q68Aaqm4AGqtvQB0rrIAea6xAHKxtgB5
s7cAdbS4AHy1uQBzu74Adbm+AH64vAAXo8kAAKbUABSy1QAdtdkAHrvbACGjyQA4uM4ALL3eABi7
4ABdssEATLbQAGOqwABmqsAAZq/AAGGtxQBqrcIAbrDBAHW8wQB5u8EAf73CAHy0yAB4v8oAZLfQ
ADrB3wAp0t8APNDaAD7N5wA23OQAQsPfAEvO2AB5wcYAf8DEAHzCygBuw9YAdsTUAGPQ2QB92NwA
RsTgAE3J4QBH3OsAUtDqAF7b7QBh1ecAWPz/AH3k8QB7//8AgKmqAImtsQCCsrQAhLa9AI67uwCR
ubwAmMC+AIe+xgCLvMQAgrjKAJy/xgCQv8oAgL7SAIi90ACCwcYAi8PHAITFzACNxMgAi8PNAIjH
zACEys8AiMnOAJTAwQCXxsgAm8bIAJvIzACGzdIAhs3UAI7J0ACIzNAAjs3SAJjD0QCTyNQAh9DU
AIvQ0wCI0tYAjdHVAIvS2ACP1NoAjNnfAJHS1gCd09QAk9XZAJvV2gCT2NoAlNjaAJHY3ACU2NwA
os3ZALLO0gCk09YArNHTAK7W2QCs298AstPWALHV2wCO2uAAk9vgAJXb4ACV3OEAl9/kAJzd5ACq
0eAAq9XgAKLZ4wCg3+YAqN7hAKjY5ACu2uUAqdznALDT4QC11eMAs9nlAJng5ACd4ucAneTnAJ3h
6gCe5uoAn+fsAI/s8wCd8vsAm///AKrg5ACi5+wAquToAKzl6wCl6e4AtOPpALrk6wC26+4At+zu
ALzq7QCk6/AAquvwAKjt8QCx7fEAuO3wAKrw8gCq8PYArPL3AK319gCm8fgArvP4ALXw8wC28/YA
vfHzALvy9gC09foAs/r+ALz//wDI19wAw9zoAMHq7QDF6e8AwuzuAN7u7wDD7fAAxu3wAMju8ADC
8fMAx/HzAMjx8gDJ8vUAzPP2AM329gDP+PcAxff6AMP8/wDK/PwA2PD0ANH//wDY//8A6P//APL/
/wD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC3uW0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6MC3ztfa
pS0JAAAAAAAAAAAAAAAAAAAAAAAAAADAwdHu8u/Z19eTjHlBAAAAAAAAAAAAAAAAAAAAAMC96fL2
8vLu6dLX15OaoC8rWQAAAAAAAAAAAADAvb3u8vLy8vLy8u7p2Nfak5OcXjJ9WwAAAAAAAAAAAMXa
4fDy8vLy8vLy8uLXw7NIaZOeoBcwlVkAAAAAAAAAw9fX4fDw8vLy8tTLpZyew8WTXImeh0V7j0GG
AAAAAADD2tfa5OLS0L2koaXD19rf5eXFa1ycsQ4sooFZAAAAALna18WzpZyJaYeJiYeHh4eVz+Xk
pVxrlUdDjI9BAAAAw7OTazolIyYnJygpNDtCSkVCw9/l14lpjQs+nH98WgBBEgcDAQEEBggMFRYk
Gh44rZA5ic/l5bNpRkpHjo8/AAAnAwIFDS57kaytq4lUIRs1qa8+PKXa5dqcSApHnkQAAAAAgWCN
zvn7+/n45Ml3c05LYbB+NofM3+XFXkSHSAAAAAAAANBrgK739+TeyHd0ZVNMUIWqMjyl1+Xlnio7
AAAAAAAAAADQjHyk13d1cXBnYlJPTVWYejaHw9fapToAAAAAAAAAAAAA6YlZmfr+/v385sp4dnJs
g3lCiJKsAAAAAAAAAAAAAAAAAACJhOfs1MNvbmhkZmNRNz0AAAAAAAAAAAAAAAAAAAAAAAAAYBkY
HB0gIh8UExEPEDMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAX4IAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAP/////////////////////////////////////////////////8f///wB///gAP//AAA/8A
AAH/AAAAfwAAAB8AAAAPAAAABwAAAAEAAAABgAAAAeAAAAH4AAAB/gAAAf+AAAP/8AAf//wAD///
/+f/////////////////////KAAAABgAAAAwAAAAAQAIAAAAAABAAgAAAAAAAAAAAAAAAQAAAAEA
AAAAAAAKNjwAH0tOACFQVgAsWV8AIFdhAClcZAA4ZGwAQGxuAEBtdQARaIMAMnePAEJ0gQBFf4YA
QnuJAAuBnwAcgp0AH5CuADOMpAA5i6EAKJSvAC2arAAsmbEAIZu7ADuuvgBEgo8AXoqMAFCQmwBV
k5wAX5CfAF+WnABjhIUAYYeKAG2XmQBmmJsAeZaVAHaZmgBIl6cARp+rAEafrABYkKEAWZWlAGOZ
pwBgnqoAaKGnAGyqrwB/oKEAeqKlAHSnqwB7o6wAe6WvAHCorQB3q68Abq61AHajswBxqrIAdKyy
AHevtQByrrgAd6+8AG+yuQB9srYAcLO5AHO0ugB5tLkAeLu/AH64vQACmsUAErjdACi52gBur8AA
d7fDAHe9wgB3vsQAe7rAAHm9wwB8uMQAfL/GAHq5zAB6vtEAM8XOADzM5gA80uYAfsHFAH7DyAB8
wcwAf8TOAF/a6wBj2u4AaNnqAHra7QBV9PUAfebwAIyvsQCArr0AgLK2AIqxsgCJsrcAkLW6AJO4
vwCMvsAAlr7CAI7CwgCBxcoAh8fJAIPHzACKx8wAg8rOAIvKzwCMys0AmMLFAJ7GxQCRxMkAnsLM
AJrFzACSyc0Als3OAJ3JyACCwNUAgsrRAITL0ACHzNcAi83SAI3N0QCLztQAjM7bAJHP0QCZyNIA
n8nRAJvJ1ACO0NUAj9PfAIzX3QCe0NAAkdXaAJTX3QCd1NgAn9bfAJTZ2wCR2NwAlNndAKLI0gCj
ytUApcrUAKzJ0wCwy9YApNDXAKbW2wCq1dwAu9beAIXV4gCB2esAhNrrAIrc6gCa1uAAl9vgAJbc
4QCZ3+MAm9vlAJjf5ACk3OAAqt3jALXd4wCb4+cAnOLlAJ7k6QCY7vcAgfPzAKfh5QCg4ukAp+fr
AKbm7ACq4eoApOrvAKft7wCq7O8AtubqALDj7QC44usAueXoALbq6wC37O8Av+nrALvp7wCm6/EA
pOzwAKju8gCq7/QAs+zwALnv9ACu8PMAq/H0AKzx9QCt9/UAo/D4AK7z+QCv9PgAsvD0ALj3/ACy
+f0Atfr9ALX8/wDK4OYAxOvuAMXt8QDB8PIAwvP0AMT09QDJ8PEAzPLzAMny9QDM8/cAyPb2AM32
9gDO+PgAyv3/ANP9+gDT//8A7vHyAPf7+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlYF5XgAAAAAAAAAAAAAAAAAA
AAAAkXGBoK6kQh0AAAAAAAAAAAAAAAAAkI2UttHRtbuLQmYqAAAAAAAAAAAAjY2izNHW0dHLvMCL
QGsjOXYAAAAAAACewM/R0dHR0dHPqptCM1SEJC5PAAAAAAClwMXP0dHMs5NtaXybaTx5aT1gTAAA
AACqwLuvqIhzanybrrvDyZ4/SHkfZHBOAACqu5tMPzU1P0xTaX6LpcnDUz9rIV91RgBHHA0GAwQH
CQwOGRxfc4vAyYtIIjNtbzqSBQECCBouXWA5JRATMW98pMm4aS0ggkIAAHFUh7XR2dbGpllFFyli
cIe7yYssQEwAAAAAtpqhsL3CXFdRREMSMWVtnru4MB0AAAAAAACziISWmZiYWlhSGCtjhXx8bTkA
AAAAAAAAALB9ytrb2cCnW1AmOoEAAAAAAAAAAAAAAAAArFQmFRYWFBEPCgsAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAADYpAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAD///8A////AP///wD///8A////AP///wD/w/8A/gH/APAA/wCAAD8AAAAfAAAADwAAAAMA
AAABAAAAAAAAAAAAwAAAAPAAAAD8AAAA/wAHAP/ABwD///MA////AP///wAoAAAAEAAAACAAAAAB
AAgAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAAAAAAAABfggAljaMALZClADaTpgA/l6gAQouhAEma
qgBTnqsAXKKtAGalrwBvqbEAeKyyADOixQBBrMsAQ63MAEWvzQBGsM4ASbLPAFC10QBZudMAW7zV
AGe/1wBowtkAdsXbAHfI3QBo0OYAcNPoAHnW6QCGzN8Ahc7kAIjP4QCC2usAjN3tAJnT4wCb1uUA
n9XlAKTY5wCq2+gAr93qAJbh7gCf5fAAqejyALLs9AC77/UAvP//AMX//wDP//8A2f//AOL//wDs
//8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAQEBAQEBAQEBAQEBAAAAAAYMCwoJCAcFBAMCAQAA
AAAGDAsKCQgHBQQDAgEAAAAAHiwrKikoISAcGxoNAAAAAB4sKyopKCEgHBsaDQAAAAAeLCsqKSgh
IBwbGg0AAAAAHiwrKikoISAcGxoNAAAAAB4sKyopKCEgHBsaDQAAAAAeLCIdGBYUExEOGg0AAAAA
HiwiMjEwLy4tDhoNAAAAAB4sJTIxMC8uLQ4aDQAAAAAeLCYyMTAvLi0RGg0AAAAAHiwmIh8ZFxQT
EhoNAAAAAAYMCwoJCAcFBAMCAQAAAAAGBgYGBgYGBgYGBgYAAAAAAAAAAAAAAAAAAAAAAADAAwAA
wAMAAMADAADAAwAAwAMAAMADAADAAwAAwAMAAMADAADAAwAAwAMAAMADAADAAwAAwAMAAMADAAD/
/wAAKAAAACAAAABAAAAAAQAgAAAAAACAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdKbGAYG0zTSOwtRUhLzS
r5zX4e1qv9HqCF59egAnQg4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgbHMQI2+1IaY
xtiyqNTf9Kzl6/+p7vH/qvHy/5PY2v9nlZv/ADtSww9tjTMAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaJ/CA4y91CR/tM5JjL3U
pafU4dy45Ov3xu3x/8rx8v/I7vD/uO3w/6nt8f+o7PH/hs7T/4jHzP+Aqqr/YKq67wd5oHsAR2YK
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAbaLBPoa4z26R
wtasqtjk8cDq7v/K8/X/z/j3/8z29v/J8vP/xu3w/8Pr7f+26+7/qOzw/6jt8f+HztL/h9DU/43a
3/91lJP/aIeM/yqRsb0AX4s3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf7jO
nJLP3sul2+bzw+3w/8329v/O9vf/zPP2/8ry9f/I8vX/yfL1/8jx8v/H7vH/wuzu/7Ht8f+p7vL/
qvDz/4bN0P+HztP/idLW/3+9wv91nZ//jru7/2Orve0Dc5t7AE9zCQAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAACd4er/rvX2/7bz9v/D8vP/yfPz/8jy9f/I8fP/yfP1/8ny9f/J8vX/yfHz/8jw
8v+98fP/quvw/53i5/+V2+D/c7u+/3nBxv+HztP/i9PY/4zZ3/9hfYD/e5ST/47J0P81kK3BAGiQ
NgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJvf5/mp7vL/qu7z/7Xw8//B8fP/x/Hz/8rz9v/M8/f/
yvP2/8jy8/++6+7/quDk/5TY2v+M09b/j9Xb/5ng5f+f5+z/h87U/3S7wf+Ax87/i9LY/4LCx/95
srf/gbK1/5XBwv9ep7rqFH6kgQAAAAMAAAAAAAAAAAAAAAAAAAAAm97m+anw8v+p7vP/rPL3/7X2
+P+78vb/t+zu/7Tm6v+o3uH/mdXZ/5HS1v+T2Nv/neTn/6bt8v+q8Pb/r/P4/7L4/v+1/P//n+br
/3zDyP93vsP/iNLW/47a4P9denv/aYyN/53T1P+Mu8H/Mo+swQBqkzcAAAAAAAAAAAAAAACe3+b5
q/Dz/6jt8v+f5ur/l9/k/5LY3f+L0NP/hMbK/3/AxP+Dwsb/h8bL/4bHyv+ExMf/hMLG/4PAxf+F
wsb/js3S/6bp7v+0+///sPf8/5HY3P90u8H/fcbM/4jM0P98tbj/ea6x/43EyP+XwMD/Y6i58QB1
n38AVnUJAAAAAJ7e5fqT2+D/hs3U/3rCyf9hoqr/S4eQ/0mDjP9Qh5D/UIiS/1OMlf9Vk53/WZSe
/1+bo/9ppKj/dK6y/365vP95tLf/dK+0/5rc4f+v8/j/t/7//6Xs8P+Axsz/ecHH/4PMz/9YaWn/
dqqu/47Q1f+YwL7/h7e9/yuLqbMAAAAKaqm4/z94gv8xZG3/G0tT/xA7Qf8VP0L/IUpN/zBXWf8/
Y2n/Sm50/013gf9LfYv/RIKT/zyGmf8/jaP/Xam7/67W2/+Xxsj/aaGl/4XDyP+k6u7/sfj9/7L5
/v+V3OH/ecLH/3W0uP9/uLz/fLa7/4jJzv+SwML/d6uv/QAAACqCy9NpPHiA3hhKUf8ZRUr/Ll1e
/0x+f/9pmZv/g7K0/5vGyP+r0NL/rtbY/6TT1v+Hxs3/XbLB/y6Zsv8Kh6n/Qp+6/6LN2f+y09b/
dais/2+prv+U2Nz/qvD1/7X7//+r8vf/iNLW/3S6vv9Va23/fLW4/4/V2/9ur7X2AAAAKAAAAACm
7fMEh8zVZGeqtsJ5v8n/hsjP/6rk6P/J+vr/0P///9L////M/v//w/z//7T3/v+d8vv/f+bz/1LQ
6v8dtdn/F6PJ/2S30P+x1dv/kbm8/2icof+AwMT/oufs/671+P+1+///nufr/3m7wf9xsbb/hcLH
/3O3vPZNTU0qAAAAAAAAAAAAAAAAktbfAqLq9UyQ1d6tf8DL/4e+xv+s29//x/f5/8P3+/+38/n/
pvH4/4/s8/955fD/Xtvt/z7N5/8Yu+D/AKbU/yGjyf+AvtL/ss7S/3Ccn/9vq67/k9fa/6br8P+0
+f7/svz//4/U2P9hh4n/ZqSp+MHBwUEAAAAAAAAAAAAAAAAAAAAAAAAAAKvt8wKw8PUuktPeqIK+
yeuCtr3/ntXc/6Do8f9/4vD/YdXn/03J4f9GxOD/QsPf/zrB3/8svd7/Hrvb/xSy1f9MttD/mMPR
/4mtsf9snqH/gMLG/5rg5P+m7PH/rPX3/5PU2P9kpqv/x8fHHAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAn+LtKI7U4YF4v8voZq/A/5PI1P/Y8PT/8v////P////o////2P///7z///+b
////e////1j8//9H3Ov/bsPW/5y/xv9/p6r8b6qv83O3vNJorLKoY6mvhF+lq3MAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJLi7B6C1uFpc7rI3pC/yv/I19z/3u7v
/7vq7P+Z4OT/fdjc/2PQ2f9Lztj/PNDa/zbc5P8p0t//OLjO/0yguvg6c4GnRHB1aDxiZwsAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAWsbXZUuqur8ui5n/EoSY/wmGn/QDe5vcAHud0QB5nccAb5fNAGWR1QBplOIAb5f2AGmT/wpr
k/8pd5DQMm5+eAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAVdLfA0CxxkQmjq5FKIuwNSiGriIukrgaM5vBEiqTuhYig7Ad
I4ayJwxxoDcOdKRBIIWvWBp8n5Ecf6CMHoGlKgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/////////////////////////////
////////////////////4B///4AP//AAA//AAAH/AAAAfwAAAD8AAAAPAAAABwAAAAEAAAAAAAAA
AAAAAACAAAAA4AAAAPgAAAD/AAAB/8AAB//4AAf//AAD/////////////////////ygAAAAYAAAA
MAAAAAEAIAAAAAAAYAkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCcHgCQnB4BQAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAgbLNAYCyzRFzpLpLfLC/g4e+zNOBytXyIXGMkQBFbBMAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGuesySBr7xSe6m7mIe0wc6d
yND4pNzg/6ft7/+c4uX/fri9/ydpfbwUmMMxAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAQnB4CF+QozJmma1of628pY68ydCq1dz+v+nr/8zy8//K8PH/t+zv/6ru8/+R2N3/fri9
/47Cwv9Rjp3kE4OvYgB2rgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABso7R7erHAq5PBztey3OL0
xOzw/8/29//O+Pj/zPX1/8jw8v/E6+7/s+zw/6zy9v+U2t3/erS5/4PKzf95lpX/da60+jeavJ8A
dqoaAAAAAAAAAAAAAAAAAAAAAAAAAACZ2+X4rvDz/8T09f/O9/b/y/P2/8ry9f/J8vX/yvL1/8rw
8v/B8PL/p+fr/5fb4P94u7//cKit/37DyP+M193/dpma/3+gof9csMfPB4GwRAAAAAAAAAAAAAAA
AAAAAACf5Or+q/H0/7Lw9P/C8/T/yPP1/8zz9//G7/L/ueXo/6bW2/+Mys7/g8fM/4vO1P+W3OH/
gcXL/2+yuf+CytH/g8TJ/32ytv+KsbL/c7PA7iqUuH4gj7QJAAAAAAAAAACf4un6rfL1/6nv9P+q
7O//p+Hl/53U2P+Syc3/isfM/4zN0f+X3eD/pOrv/6nt8v+u8/n/tfz//5nf4/9ztLr/d73C/4TL
0P9jhIX/jL7A/5LEyf88mbWtAYCxKgAAAACl5uz6qO/z/5bd4/98v8b/cLO5/2+vtv9trrX/c7S7
/3m9w/9+wMT/h8fJ/5HP0f+U2dv/neTp/7X6/f+v9Pj/f8LH/3Czuv+Dy8//bZeZ/4Gztv+dycj/
WaS33hOIslF3t8P/VZOc/0V/hv8pXGT/IVBW/yxZX/84ZGz/QG11/0J0gf9Ce4n/RIKP/1CQm/+A
sbb/ls3O/5HY3P+s8fX/s/r+/5TZ3v93vsT/Zpib/3err/+Lys//nsbF/2qptPButL+fH1Zg/Qo2
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
AADAAwAAwAMAAMADAADAAwAAwAMAAP//AAA=')
    $FormOU.MaximizeBox = $False
    $FormOU.MinimizeBox = $False
    $FormOU.Text = "Select your Active Directory OU(s):"
    $FormOU.add_Load($FormEvent_Load)

    $Treeview = New-Object System.Windows.Forms.TreeView
    $Treeview.Name = 'treeview1'
    $Treeview.Location = '19, 21'
    $Treeview.Size = '301, 425'  
    $Treeview.ImageIndex = 0
    $Treeview.SelectedImageIndex = 0
    $Treeview.ImageList = $Imagelist1 
    $Treeview.CheckBoxes = $True
    $Treeview.TabIndex = 0
    $Treeview.Add_AfterCheck($Treeview_AfterCheck)
    $FormOU.Controls.Add($Treeview)

    $NodeRoot = New-Object System.Windows.Forms.TreeNode ('Active Directory Hierarchy', 3, 3)
    $NodeRoot.ImageIndex = 3
    $NodeRoot.Name = 'Active Directory Hierarchy'
    $NodeRoot.SelectedImageIndex = 3
    $NodeRoot.Tag = 'root'
    $NodeRoot.Text = 'Active Directory Hierarchy'
    $Treeview.Nodes.Add($NodeRoot) | Out-Null

    $ButtonOK = New-Object System.Windows.Forms.Button
    $ButtonOK.Anchor = 'Bottom, Right'
    $ButtonOK.Location = '245, 467'
    $ButtonOK.Name = 'ButtonOK'
    $ButtonOK.Size = '75, 23'
    $ButtonOK.TabIndex = 1
    $ButtonOK.Text = 'OK'
    $ButtonOK.UseVisualStyleBackColor = $True
    $ButtonOK.add_Click($ButtonOK_Click)
    $FormOU.Controls.Add($ButtonOK)
   
    $ButtonCancel = New-Object System.Windows.Forms.Button
    $ButtonCancel.text = “&Cancel”
    $ButtonCancel.Location = '19,467'
    $ButtonCancel.TabIndex = 2
    $ButtonCancel.size = '75,23'
    $ButtonCancel.Anchor = 'Bottom, Left'
    $ButtonCancel.add_Click($ButtonCancel_Click)
    $FormOU.Controls.Add($ButtonCancel)

    $Formatter_binaryFomatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $System_IO_MemoryStream = New-Object System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String('
AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAu
MC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAA
ACZTeXN0ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkD
AAAADwMAAABwCgAAAk1TRnQBSQFMAgEBBAEAAUABAAFAAQABEAEAARABAAT/AQkBAAj/AUIBTQE2
AQQGAAE2AQQCAAEoAwABQAMAASADAAEBAQABCAYAAQgYAAGAAgABgAMAAoABAAGAAwABgAEAAYAB
AAKAAgADwAEAAcAB3AHAAQAB8AHKAaYBAAEzBQABMwEAATMBAAEzAQACMwIAAxYBAAMcAQADIgEA
AykBAANVAQADTQEAA0IBAAM5AQABgAF8Af8BAAJQAf8BAAGTAQAB1gEAAf8B7AHMAQABxgHWAe8B
AAHWAucBAAGQAakBrQIAAf8BMwMAAWYDAAGZAwABzAIAATMDAAIzAgABMwFmAgABMwGZAgABMwHM
AgABMwH/AgABZgMAAWYBMwIAAmYCAAFmAZkCAAFmAcwCAAFmAf8CAAGZAwABmQEzAgABmQFmAgAC
mQIAAZkBzAIAAZkB/wIAAcwDAAHMATMCAAHMAWYCAAHMAZkCAALMAgABzAH/AgAB/wFmAgAB/wGZ
AgAB/wHMAQABMwH/AgAB/wEAATMBAAEzAQABZgEAATMBAAGZAQABMwEAAcwBAAEzAQAB/wEAAf8B
MwIAAzMBAAIzAWYBAAIzAZkBAAIzAcwBAAIzAf8BAAEzAWYCAAEzAWYBMwEAATMCZgEAATMBZgGZ
AQABMwFmAcwBAAEzAWYB/wEAATMBmQIAATMBmQEzAQABMwGZAWYBAAEzApkBAAEzAZkBzAEAATMB
mQH/AQABMwHMAgABMwHMATMBAAEzAcwBZgEAATMBzAGZAQABMwLMAQABMwHMAf8BAAEzAf8BMwEA
ATMB/wFmAQABMwH/AZkBAAEzAf8BzAEAATMC/wEAAWYDAAFmAQABMwEAAWYBAAFmAQABZgEAAZkB
AAFmAQABzAEAAWYBAAH/AQABZgEzAgABZgIzAQABZgEzAWYBAAFmATMBmQEAAWYBMwHMAQABZgEz
Af8BAAJmAgACZgEzAQADZgEAAmYBmQEAAmYBzAEAAWYBmQIAAWYBmQEzAQABZgGZAWYBAAFmApkB
AAFmAZkBzAEAAWYBmQH/AQABZgHMAgABZgHMATMBAAFmAcwBmQEAAWYCzAEAAWYBzAH/AQABZgH/
AgABZgH/ATMBAAFmAf8BmQEAAWYB/wHMAQABzAEAAf8BAAH/AQABzAEAApkCAAGZATMBmQEAAZkB
AAGZAQABmQEAAcwBAAGZAwABmQIzAQABmQEAAWYBAAGZATMBzAEAAZkBAAH/AQABmQFmAgABmQFm
ATMBAAGZATMBZgEAAZkBZgGZAQABmQFmAcwBAAGZATMB/wEAApkBMwEAApkBZgEAA5kBAAKZAcwB
AAKZAf8BAAGZAcwCAAGZAcwBMwEAAWYBzAFmAQABmQHMAZkBAAGZAswBAAGZAcwB/wEAAZkB/wIA
AZkB/wEzAQABmQHMAWYBAAGZAf8BmQEAAZkB/wHMAQABmQL/AQABzAMAAZkBAAEzAQABzAEAAWYB
AAHMAQABmQEAAcwBAAHMAQABmQEzAgABzAIzAQABzAEzAWYBAAHMATMBmQEAAcwBMwHMAQABzAEz
Af8BAAHMAWYCAAHMAWYBMwEAAZkCZgEAAcwBZgGZAQABzAFmAcwBAAGZAWYB/wEAAcwBmQIAAcwB
mQEzAQABzAGZAWYBAAHMApkBAAHMAZkBzAEAAcwBmQH/AQACzAIAAswBMwEAAswBZgEAAswBmQEA
A8wBAALMAf8BAAHMAf8CAAHMAf8BMwEAAZkB/wFmAQABzAH/AZkBAAHMAf8BzAEAAcwC/wEAAcwB
AAEzAQAB/wEAAWYBAAH/AQABmQEAAcwBMwIAAf8CMwEAAf8BMwFmAQAB/wEzAZkBAAH/ATMBzAEA
Af8BMwH/AQAB/wFmAgAB/wFmATMBAAHMAmYBAAH/AWYBmQEAAf8BZgHMAQABzAFmAf8BAAH/AZkC
AAH/AZkBMwEAAf8BmQFmAQAB/wKZAQAB/wGZAcwBAAH/AZkB/wEAAf8BzAIAAf8BzAEzAQAB/wHM
AWYBAAH/AcwBmQEAAf8CzAEAAf8BzAH/AQAC/wEzAQABzAH/AWYBAAL/AZkBAAL/AcwBAAJmAf8B
AAFmAf8BZgEAAWYC/wEAAf8CZgEAAf8BZgH/AQAC/wFmAQABIQEAAaUBAANfAQADdwEAA4YBAAOW
AQADywEAA7IBAAPXAQAD3QEAA+MBAAPqAQAD8QEAA/gBAAHwAfsB/wEAAaQCoAEAA4ADAAH/AgAB
/wMAAv8BAAH/AwAB/wEAAf8BAAL/AgAD//8A/wD/AP8ABQAk/wL0Bv8D9AP/DPQD/wp0BHMC/wp0
BHMC/wPsAesBbQH3Av8BBwLsAesBcgFtAfQC/wwqA/8BdAGaA3kBegd5AXMC/wF0AZoDeQF6B3kB
cwL/AfcBBwGYATQBVgH3Av8BvAHvAQcBVgE5AXIB9AL/AVEBHAF0A3MFUQEqA/8BeQKaBUsFmgF0
Av8BeQyaAXQC/wHvAQcB7wJ4AZIC8QMHAXgBWAHrAfQC/wF0ApkCeQN0A1IBKgP/AXkCmgFLA1EB
KgWaAXQC/wF5DJoBdAL/Ae8CBwHvAZIC7AFyAe0CBwLvAewB9AL/AZkCGgGgBJoCegF5AVID/wF5
AaABmgF5AZkCeQFRBZoBdAL/AXkBoAuaAXQC/wEHAe8C9wLtAXgBNQF4Ae8D9wHsAfQC/wGZAhoB
oASaAnoBeQFSA/8BeQGgAZoCmQGgAXkBUgWaAXQC/wF5AaALmgF0Av8BBwPvAfcB7QGYAXgBmQEH
A+8B7AP/AZkCGgGgBJoCegF5AVID/wGZAaABmgGZAXkBmgF5AVIFmgF0Av8BmQGgC5oBdAL/AbwD
8wG8AZIBBwHvAQcB8QLzAfIB7QP/AZkCGgGgBJoCegF5AVID/wGZAaABmgJ5AXQCUgWaAXQC/wGZ
AaALmgF0Av8BvAEHAu8B9wPtAe8CBwLvAe0D/wGZARoBmgKZBnkBUgP/AZkBwwGaBHQBeQGgBJoB
dAL/AZkBwwaaAaAEmgF0Av8CvAIHAvcCBwO8AgcBkgP/AZkBGgGZAxoDmgFSAXkBUgP/AZkBwwOa
AqABmQWaAXQC/wGZAcMDmgKgAZkFmgF0Av8CvAHrAewCBwLzAfABvAHtAW0BBwH3A/8BmQEaAZkC
9gTDAVIBeQFSA/8BmQWgAZoCdAV5Av8BmQWgAZoCdAV5Av8BvAEHApIB7wH3ApIB7wG8Ae8BkgHv
AfcD/wGZAhoC9gTDAVgBeQFSA/8BmQGaBBoBdAOaApkBmgF5Av8BeQGaBBoBdAOaApkBmgF5Av8D
9AHyAbwB8QK8Ae8B8AT0A/8BmQMaApkDeQFYAXkBUgP/ARsGeQGaAvYB1gG0AZoBmQL/AZkGeQGa
AvYB1gG0AZoBeQX/AfQBvAH3ARIB7AHvAfAH/wFRARwBeQN0AVIEUQEqCf8BwwZ5AcMI/wGaBnkB
mgX/AfQBvAEHAu8B9wHxB/8MUUL/AUIBTQE+BwABPgMAASgDAAFAAwABIAMAAQEBAAEBBgABARYA
A///AAIACw=='))
    $Imagelist1.ImageStream = $Formatter_binaryFomatter.Deserialize($System_IO_MemoryStream)
    $Formatter_binaryFomatter = $null
    $System_IO_MemoryStream = $null
    $Imagelist1.TransparentColor = 'Transparent'
    $ErrorProviderOU.ContainerControl = $FormOU
    $InitialFormWindowState = $FormOU.WindowState

    $FormOU.add_Load($Form_StateCorrection_Load)
    $FormOU.add_FormClosed($Form_Cleanup_FormClosed)
    $FormOU.ShowDialog() | Out-Null
}

show-FormOUSelector } )

########10101010101010####################
    $form.AcceptButton = $ouButton
    $form.Controls.Add($ouButton)


    #$listBox = New-Object System.Windows.Forms.ListBox
   
######################################################################################################################################### 
    #add OU

    ##Define text label4
    $textLabel4 = New-Object “System.Windows.Forms.Label”;
    $textLabel4.Left = 50;
    $textLabel4.Top = 70;
    $textLabel4.Size = New-Object System.Drawing.Size(260,40)
    $textLabel4.Text = "First Name:";
    $textLabel4.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel4)

    ##Define text box4 for input
    $textBox4 = New-Object “System.Windows.Forms.TextBox”;
    $textBox4.Left = 350;
    $textBox4.Top = 70;
    $textBox4.Size = New-Object System.Drawing.Size(350,40)
    $textBox4.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    $textBox4.Text = $fname
    $form.Controls.Add($textBox4);

###########################################################################################################################################

##Define text label5
    $textLabel5 = New-Object “System.Windows.Forms.Label”;
    $textLabel5.Left = 50;
    $textLabel5.Top = 120;
    $textLabel5.Size = New-Object System.Drawing.Size(260,40)
    $textLabel5.Text = "Last Name:";
    $textLabel5.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel5)

    ##Define text box5 for input
    $textBox5 = New-Object “System.Windows.Forms.TextBox”;
    $textBox5.Left = 350;
    $textBox5.Top = 120;
    $textBox5.Size = New-Object System.Drawing.Size(350,40)
    $textBox5.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox5.Text = $lname
    $form.Controls.Add($textBox5);

#############################################################################################################################################
  
       ##Define text label3 **UPN**
    $textLabel3 = New-Object “System.Windows.Forms.Label”;
    $textLabel3.Left = 50;
    $textLabel3.Top = 180;
    $textLabel3.Text = "Username:";
    $textLabel3.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel3)

    ##Define text box3 for input **UPN***
    $textBox3 = New-Object “System.Windows.Forms.TextBox”;
    $textBox3.Left = 50;
    $textBox3.Top = 220;
    $textBox3.Size = New-Object System.Drawing.Size(300,40)
    $textBox3.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox3.Text = $upn
    $form.Controls.Add($textBox3);

    ##Define text upn domain
    $textLabel7 = New-Object “System.Windows.Forms.Label”;
    $textLabel7.Left = 380;
    $textLabel7.Top = 180;
    $textLabel7.Text = "UPN Domain:";
    $textLabel7.size = New-Object System.Drawing.Size(250,25)
    $textLabel7.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel7)

    ##Define listbox for input - upn domain
    $listbox2 = New-Object System.Windows.Forms.ComboBox
    $listbox2.Left = 380;
    $listbox2.Top = 220;
    $listbox2.Size = New-Object System.Drawing.Size(320,40)
    $listbox2.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    (Get-ADDomain).DNSroot | ForEach-Object { $listbox2.Items.Add($_) | Out-Null } 
    (Get-ADForest).upnsuffixes | ForEach-Object { $listbox2.Items.Add($_) | Out-Null}
    $form.Controls.Add($listbox2)
    
    ##Define text @
    $textLabel8 = New-Object “System.Windows.Forms.Label”;
    $textLabel8.Left = 360;
    $textLabel8.Top = 225;
    $textLabel8.Text = "@";
    $textLabel8.Font = New-Object System.Drawing.Font("Lucida Console",14,[System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($textLabel8) 

########################################################################################################################################################
    ##Define text label -for title
    $textLabel6 = New-Object “System.Windows.Forms.Label”;
    $textLabel6.Left = 50;
    $textLabel6.Top = 280;
    $textLabel6.Size = New-Object System.Drawing.Size(260,40)
    $textLabel6.Text = "Title:";
    $textLabel6.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel6)

    ##Define text box for input - for title
    $textBox6 = New-Object “System.Windows.Forms.TextBox”;
    $textBox6.Left = 350;
    $textBox6.Top = 270;
    $textBox6.Size = New-Object System.Drawing.Size(350,40)
    $textBox6.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox6.Text = $title
    $form.Controls.Add($textBox6);

##########################################################################################################################################################    

#phone

 $textLabel11 = New-Object “System.Windows.Forms.Label”;
    $textLabel11.Left = 50;
    $textLabel11.Top = 340;
    $textLabel11.Size = New-Object System.Drawing.Size(260,40)
    $textLabel11.Text = "Phone:";
    $textLabel11.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel11)

    ##Define text box for input - for phone
    $textBox11 = New-Object “System.Windows.Forms.TextBox”;
    $textBox11.Left = 350;
    $textBox11.Top = 340;
    $textBox11.Size = New-Object System.Drawing.Size(200,40)
    $textBox11.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox11.Text = $phone
    $form.Controls.Add($textBox11);

    
 $textLabel111 = New-Object “System.Windows.Forms.Label”;
    $textLabel111.Left = 575;
    $textLabel111.Top = 320;
    $textLabel111.Size = New-Object System.Drawing.Size(100,20)
    $textLabel111.Text = "EXT:";
    $textLabel111.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel111)

     $textBox111 = New-Object “System.Windows.Forms.TextBox”;
    $textBox111.Left = 570;
    $textBox111.Top = 340;
    $textBox111.Size = New-Object System.Drawing.Size(100,40)
    $textBox111.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox111.Text = $phone
    $form.Controls.Add($textBox111);
##########################################################################################################################################################

#Password

$textLabel12 = New-Object “System.Windows.Forms.Label”;
    $textLabel12.Left = 50;
    $textLabel12.Top = 400;
    $textLabel12.Size = New-Object System.Drawing.Size(260,40)
    $textLabel12.Text = "Password:";
    $textLabel12.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel12)

    ##Define text box for input - for phone
    $textBox12 = New-Object “System.Windows.Forms.TextBox”;
    $textBox12.Left = 350;
    $textBox12.Top = 400;
    $textBox12.Size = New-Object System.Drawing.Size(350,40)
    $textBox12.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox12.Text = $Password
    $form.Controls.Add($textBox12);

##########################################################################################################################################################

            
    ##Define text label9
    $textLabel9 = New-Object “System.Windows.Forms.Label”;
    $textLabel9.Left = 50;
    $textLabel9.Top = 470;
    $textLabel9.Size = New-Object System.Drawing.Size(260,40)
    $textLabel9.Text = "Ticket Number:";
    $textLabel9.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($textLabel9)

    ##Define text box9 for input
    $textBox9 = New-Object “System.Windows.Forms.TextBox”;
    $textBox9.Left = 350;
    $textBox9.Top = 470;
    $textBox9.Size = New-Object System.Drawing.Size(350,40)
    $textBox9.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox9.Text = $Ticket
    $form.Controls.Add($textBox9);

################################################################################################################################################################

    ##Define OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(400,550)
    $okButton.Size = New-Object System.Drawing.Size(100,50)
    $okButton.Text = 'ADD'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    ##Define Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(550,550)
    $cancelButton.Size = New-Object System.Drawing.Size(100,50)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)
    $form.Topmost = $false

     ##Define text label2 USERNAME
    $textLabel2 = New-Object “System.Windows.Forms.Label”;
    $textLabel2.Left = 50;
    $textLabel2.Top = 70;
    $textLabel2.Size = New-Object System.Drawing.Size(260,40)
    $textLabel2.Text = "UserName:"
    $textLabel2.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Bold)
    #$form.Controls.Add($textLabel2);

    ##Define text box2 for input USERNAME
    $textBox2 = New-Object “System.Windows.Forms.TextBox”;
    $textBox2.Left = 350;
    $textBox2.Top = 70;
    $textBox2.Size = New-Object System.Drawing.Size(350,40)
    $textBox2.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    #$textBox2.Text = $username
    #$form.Controls.Add($textBox2);
###################################################################################################################################################
    $global:ret = $form.ShowDialog() 
   


        ###  if ($ret -eq [System.Windows.Forms.DialogResult]::OK)
        if ($ret -eq 'OK'){
            #set the input values
            $OU = $script:SelectedOU
            $username = $textBox3.Text
            $password = $textBox12.Text
            $upn = $textBox3.Text
            $fname = $textBox4.Text
            $lname = $textBox5.Text
            $title = $textBox6.Text
           $domainUPN = $listbox2.SelectedItem
			$email="$upn" + "@" + "$domainUPN"
            $tktnum = $textBox9.Text 
            $phone =  $textBox111.Text + $textBox11.Text
            #"$textBox111.Text" +
            #$email = "test@test.com"
            $err = $null

            "OU = $OU"
            "Username = $username"
            "upn = $upn"
            "fname = $fname"
            "lname = $lname"
            "title = $title"
            "upndomain = $domainUPN"
           "phone = $phone"
            "tktnum = $tktnum"


            #check if any of the input values are empty
            if ($OU -like "$null"){        
                    $err +="Select an OU from dropdown`n"
            
            }

            if ($username -like "$null" -OR $username -like " " -OR $username -like ""){
                    $err += "Username cannot be null or contain spaces`n"
            
            }
      
            if ($upn -like "$null" -OR $upn -like " " -OR $upn -like ""){
                $err += "UPN cannot be null or contain spaces`n"
            
            }
        
            if ($fname -like "$null"){
                $err += "First Name cannot be null `n"
            
            }
        
            if ($lname -like "$null"  -OR $lname -like " " -OR $lname -like ""){
                $err += "Last Name cannot be null or contain spaces`n"
            
            }
            if ($domainUPN -like "$null"  -OR $domainUPN -like " " -OR $domainUPN -like ""){
                $err += "Upn domain cannot be null or contain spaces`n"
            
            } 
            if ($tktnum -like "$null"  -OR $tktnum -like " " -OR $tktnum -like ""){
                $err += "Ticket Number cannot be null.`n"
            
            }
            if ($phone -like "$null"  -OR $phone -like " " -OR $phone -like ""){
                $err += "Phone Number cannot be null.`n"
            
            }
            #$err
  
            #display error message if any
            if ("$err" -notlike "$null"){
                [System.Windows.MessageBox]::Show($err,'Error Message','OK','Error')
                $ret=$null
                show_gui
            }
            else{
                $err = $null
                #check if any user exists with the new username
                if (Get-ADuser -F {SamAccountName -like $username}){
                    $err= "A user already exists with the username: $username"
                    [System.Windows.MessageBox]::Show($err,'Error Message','OK','Error')
            
                    show_gui
                }
                else{
                    ##create new user
                    #default password
                    #$password = "P@ssw0rd"
                    $timestamp = Get-Date
                    try {
                        New-ADUser -SamAccountName $username `
			            -Name "$fname $lname" `
			            -GivenName $fname `
			            -Surname $lname `
                        -title $title `
                        -Description "$title" `
			            -Enabled $True `
			            -DisplayName "$lname, $fname" `
			            -Path "$OU" `
                        -EmailAddress "$email" `
                        -UserPrincipalName "$email" `
			            -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
			            -ChangePasswordAtLogon $true `
                        -OfficePhone "$phone" `
                        -OtherAttributes @{'extensionattribute10'="$tktnum, $timestamp"}
                        start-sleep 2
                        if (Get-ADuser -F {SamAccountName -eq $username}){   
                           Set-ADUser -Identity "$username" –replace @{extensionattribute10 = "$tktnum"}  
                            [System.Windows.MessageBox]::Show("User Created Sucecessfully : $username",'',"ok","Information")
                            
                        }
                    }
                    catch{
                        $err= "An error occurred while creating user: $_ `nPlease try again."
                        [System.Windows.MessageBox]::Show($err,'Error Message','OK','Error')
                        $err = $null
                        $ret = $null                
                    }
                }
            } 
        }
    

}
$ret="OK"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ( $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true ){
    while ($ret -eq "OK"){
        show_gui
    }
    $form.Close()
    $ret=$null
 }
 else{
    [System.Windows.MessageBox]::Show("Run powershell as Admin",'Error Message','OK','Error')
 }
