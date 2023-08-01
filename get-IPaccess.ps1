[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Type
)

if ($Type -eq "Network ACL"){

    $existingrules = aws ec2 describe-network-acls
    $Rules = ($existingrules | convertfrom-Json | Select-Object -ExpandProperty NetworkAcls).Entries | Select-Object -Property CidrBlock,Ruleaction,RuleNumber

    Write-Output $rules | Where-Object CidrBlock -NE "0.0.0.0/0"
}