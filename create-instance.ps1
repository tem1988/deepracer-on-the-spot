[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $baseResourcesStackName="alfetta-stack",

    [string]
    $stackName,

    [int]
    $timeToLiveInMinutes,

    [string]
    [ValidateSet("g4dn.2xlarge","g4dn.4xlarge","g4dn.8xlarge","g4dn.12xlarge")]
    $machinetype,

    [string]
    [ValidateSet("spot","standard")]
    $EC2Type
)

$stackName = $stackName.TrimEnd("`r")
$EC2Type = $EC2Type.TrimEnd("`r")
$machinetype = $machinetype.TrimEnd("`r")
$baseResourcesStackName = $baseResourcesStackName.TrimEnd("`r")
#Set-PSDebug -Trace 2

if (-not $DEEPRACER_INSTANCE_TYPE) {
    $instanceTypeConfig=$machinetype
}
else {
    $instanceTypeConfig=$DEEPRACER_INSTANCE_TYPE
}

Write-Output "EC2 Type = $EC2Type"
Write-Output "baseResourcesStackName = $baseResourcesStackName"
Write-Output "stackName = $stackName"
Write-Output "timeToLiveInMinutes = $ttl"
Write-Output "instanceTypeConfig = $instanceTypeConfig"

if ($EC2Type -eq "spot"){
    $templateFile = "spot-instance.yaml"
}
else {
    $templateFile = "standard-instance.yaml"
}
Write-Output "Template file = $templateFile"


Pause

$BUCKET = (aws cloudformation describe-stacks --stack-name $baseResourcesStackName)
$BUCKET = ($BUCKET | ConvertFrom-Json).Stacks.Outputs | Where-Object OutputKey -EQ "Bucket" | Select-Object -ExpandProperty OutputValue
$amiId = (aws ec2 describe-images --owners 747447086422 --filters "Name=state,Values=available" "Name=is-public,Values=true")
$amiId = ($amiId | ConvertFrom-Json).Images | Sort-Object -Property CreationDate | Select-Object -Last 1 -ExpandProperty ImageId

Write-Output "BUCKET = $BUCKET"
Write-Output "amiId = $amiId"
Pause

& .\validation.ps1

if ($LASTEXITCODE -ne 0){
    Write-Output "Errors founds in validation"
    Exit 1
}

$CUSTOM_FILE_LOCATION= $DR_LOCAL_S3_CUSTOM_FILES_PREFIX

aws s3 cp .\custom-files\ s3://$BUCKET/$CUSTOM_FILE_LOCATION/ --recursive
pause

aws cloudformation deploy --stack-name $stackName --parameter-overrides InstanceType=$instanceTypeConfig ResourcesStackName=$baseResourcesStackName TimeToLiveInMinutes=$timeToLiveInMinutes AmiId=$amiId BUCKET=$BUCKET CUSTOMFILELOCATION=$CUSTOM_FILE_LOCATION --template-file $templateFile --capabilities CAPABILITY_IAM --s3-bucket $BUCKET --force-upload

$ASG = aws cloudformation describe-stacks --stack-name $stackName
$ASG = ($asg | ConvertFrom-Json).stacks.outputs.outputvalue
$EC2_ID = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG
$EC2_ID = ($ec2_id  | ConvertFrom-Json).autoscalinggroups.instances.instanceid


if ($EC2Type -eq "spot"){
    $EC2_IP= (aws ec2 describe-instances --instance-ids ${EC2_ID}) #  --query 'Reservations[].Instances[].PublicIpAddress[]' --output text)
    $EC2_IP = ($EC2_IP | ConvertFrom-Json).reservations.instances.publicipaddress
    }
else {
    $EC2_IP= aws cloudformation list-exports --query "Exports[?Name=='${stackName}-PublicIp'].Value"
    $EC2_IP = $EC2_IP | ConvertFrom-Json
}


Write-Output "Logs will upload every 2 minutes to https://s3.console.aws.amazon.com/s3/buckets/$($BUCKET)/$($stackName)/logs/"
Write-Output "Training should start shortly on $($EC2_IP):8080"
Write-Output "Once started, you should also be able to monitor training progress through $($EC2_IP):8100/menu.html"
exit