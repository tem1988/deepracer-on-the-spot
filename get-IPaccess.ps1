[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Type,

    [string]
    $stackName
)

if ($Type -eq "Network ACL"){

    $existingrules = aws ec2 describe-network-acls
    $Rules = ($existingrules | convertfrom-Json | Select-Object -ExpandProperty NetworkAcls).Entries | Select-Object -Property CidrBlock,Ruleaction,RuleNumber

    Write-Output $rules | Where-Object CidrBlock -NE "0.0.0.0/0"
}
elseif ($Type -eq "Security Group ACL") {

    $filter = "Name=tag-value,Values=$stackname"

    $existingSecrules = aws ec2 describe-security-groups --filters $filter
    $SecGroupACL = $existingSecrules | convertfrom-Json | Select-Object -ExpandProperty SecurityGroups | Where-Object GroupName -NotMatch "EFS"
    Write-Output "$($SecGroupACL.IpPermissions.IpRange)"

    $SecGroupACL
}