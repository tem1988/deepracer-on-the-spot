[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $baseResourcesStackName="Tomas-IP-Casa",

    [string]
    $stackName="alfetta-stack",

    [string]
    $ipAddress="152.168.254.233"
)

function Get-RuleNumber {

    $existingrules = aws ec2 describe-network-acls
    $existing_rule_numbers = ($existingrules | ConvertFrom-Json).NetworkAcls.Entries | Select-Object -Property RuleNumber | Sort-Object -Property RuleNumber -Unique

    do {
        $rule_number_candidate = Get-Random -Minimum 1 -Maximum 32000
    } while (
        $rule_number_candidate -in $existing_rule_numbers
    )
    return $rule_number_candidate

}

$ruleN = Get-RuleNumber

$templateAddAccess = ".\scripts\add-access.yaml"

aws cloudformation deploy --stack-name $stackName --parameter-overrides ResourcesStackName=$baseResourcesStackName MyIPAddress=$ipAddress RuleNumber=$ruleN --template-file $templateAddAccess
