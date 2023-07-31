function set-runEnvVariables {
    Get-Content .\custom-files\run.env | ForEach-Object {
        $pair = $_.Split("=")
        if ($pair.Length -eq 2) {
            Set-Variable -Name $pair[0] -Value  $pair[1] -Scope Script
        }
    }
}

function update-runEnvVariables {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $key,

        [string]
        $value
    )

    $File = Get-Content .\custom-files\run.env

    for ($i = 0; $i -lt $File.Length; $i++) {
        # Check if the line starts with the key
        if ($File[$i] -like "$key=*") {
            # Replace the line with the new value
            $File[$i] = "$key=$value"
            break
        }
    }

    $File | Out-File -FilePath .\custom-files\run.env -Encoding utf8

}

function update-hyperParameters {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $key,

        [string]
        $value
    )

    $hyperparameters = get-content custom-files/hyperparameters.json -Raw | ConvertFrom-Json
    $hyperparameters.$key = $value

    $hyperparameters | ConvertTo-Json | Set-Content -Path custom-files/hyperparameters.json

}

function update-actionSpace {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Action,

        [Parameter()]
        [string]
        $key,

        [Parameter()]
        [string]
        $value
    )


    $model_metadata = (get-content custom-files/model_metadata.json -Raw | ConvertFrom-Json)

    if ($Action -eq "Add") {
        $newActionSpace = @{
            "steering_angle" = $key
            "speed"          = $value
        }
        $newObject = New-Object PSObject -Property $newActionSpace
        $model_metadata.action_space += $newObject

        $model_metadata | ConvertTo-Json | Set-Content -Path custom-files/model_metadata.json

    }
    elseif ($Action -eq "Remove") {
        $model_metadata.action_space = $model_metadata.action_space | Where-Object { $_.steering_angle -ne $key }
        $model_metadata | ConvertTo-Json | Set-Content -Path custom-files/model_metadata.json

    }

}

$hyperparameters = get-content custom-files/hyperparameters.json | ConvertFrom-Json
$model_metadata = get-content custom-files/model_metadata.json | ConvertFrom-Json


function Show-Menu {

    Write-Host "--- AWS Console (CLI Version) ---"
    Write-Host "---Configuration---"

    Write-Output "1 - Add IP access"
    Write-Output "2 - Remove IP access"
    Write-Output "3 - Start Training"
    Write-Output "4 - Quit"

}

function Start-AWSTraining {

    Write-Output "DR_LOCAL_S3_MODEL_PREFIX: $($DR_LOCAL_S3_MODEL_PREFIX)"
    Write-Output "DR_LOCAL_S3_PRETRAINED_PREFIX: $($DR_LOCAL_S3_PRETRAINED_PREFIX)"

    Write-Output "Select EC2 type:"
    Write-Output "1. spot"
    Write-Output "2. standard"
    $standardspot = read-host "Enter your choice (1-2)"

    if ($standardspot -eq 1) { $standardspot = "spot" }
    elseif ($standardspot -eq 2) { $standardspot = "standard" }
    else {
        Write-Output "Invalid Choice"
        exit
    }
    Write-Output "Pick HW configuration:"
    Write-Output "1. g4dn.2xlarge (RECOMMENDED. any larger will be more expensive)"
    Write-Output "2. g4dn.4xlarge"
    Write-Output "3. g4dn.8xlarge"
    Write-Output "4. g4dn.12xlarge"
    Write-Output "5. g5.2xlarge"
    Write-Output "6. g5.4xlarge"
    Write-Output "7. g5.8xlarge"
    Write-Output "8. g5.12xlarge"
    Write-Output "9. Custom"
    $machinetype = read-host "Enter your choice (1-9)"
    if ($machinetype -EQ 1) {
        $machinetype = "g4dn.2xlarge"
    }
    elseif ($machinetype -EQ 2) {
        $machinetype = "g4dn.4xlarge"
    }
    elseif ($machinetype -EQ 3) {
        $machinetype = "g4dn.8xlarge"
    }
    elseif ($machinetype -EQ 4) {
        $machinetype = "g4dn.12xlarge"
    }
    elseif ($machinetype -EQ 5) {
        $machinetype = "g5.2xlarge"
    }
    elseif ($machinetype -EQ 6) {
        $machinetype = "g5.4xlarge"
    }
    elseif ($machinetype -EQ 7) {
        $machinetype = "g5.8xlarge"
    }
    elseif ($machinetype -EQ 8) {
        $machinetype = "g5.12xlarge"
    }
    elseif ($machinetype -EQ 9) {
        $machinetype = "Custom"
    }
    else {
        Write-Output "Invalid Choice"
        exit
    }

    $ttl = read-host "Insert Time to live (Minutes):"

    .\create-instance.ps1 -baseResourcesStackName $STACK -stackName $DR_LOCAL_S3_MODEL_PREFIX -timeToLiveInMinutes $ttl -machinetype $machinetype -EC2Type $standardspot

}

do {
    set-runEnvVariables

    $hyperparameters = get-content custom-files/hyperparameters.json | ConvertFrom-Json
    $model_metadata = get-content custom-files/model_metadata.json | ConvertFrom-Json
    Show-Menu

    $selection = Read-Host "Pick a menu item (0-17):"
    switch ($selection) {
        '1' {
            Write-Output "Add IP access"
            .\add-remove-access.ps1
        }
        '2' {
            Write-Output "Remove IP access"
            .\add-remove-access.ps1
        }
        '3' {
            Start-AWSTraining
        }
    }
}
until ($selection -eq '0')