$pswsafe = Import-CSV C:\Users\Vembarasan.T\Desktop\Test\NewPD.csv

$pswsafe | ForEach-Object {
$Title = $_.Title;
$ContentType = $_.Username;
$Password = convertto-securestring -string $_.Password -asplaintext -force
Set-AzKeyVaultSecret -VaultName "Keyvault name" -Name $_.Title -SecretValue $Password -ContentType $ContentType
}
#Get-AzKeyVaultSecret -VaultName "Keyvault name" | select ContentType | sort ContentType
