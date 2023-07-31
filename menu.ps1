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

$OPTIONS = [PSCustomObject] @{

    1  = [PSCustomObject] @{ "label" = "Modify Model Name"; "file" = "custom-files/run.env"; "key" = "DR_LOCAL_S3_MODEL_PREFIX"; "dtype" = "string" }
    2  = [PSCustomObject] @{ "label" = "Modify Car Name"; "file" = "custom-files/run.env"; "key" = "DR_CAR_NAME"; "dtype" = "string" }
    3  = [PSCustomObject] @{ "label" = "Modify Circuit"; "file" = "custom-files/run.env"; "key" = "DR_WORLD_NAME"; "dtype" = "string" }
    4  = [PSCustomObject] @{ "label" = "Modify Race Type (TT;OA;H2H)"; "file" = "custom-files/run.env"; "key" = "DR_RACE_TYPE"; "dtype" = "string" }
    5  = [PSCustomObject] @{ "label" = "Modify Batch Size"; "file" = "custom-files/hyperparameters.json"; "key" = "batch_size"; "dtype" = "int" }
    6  = [PSCustomObject] @{ "label" = "Modify Beta_entropy"; "file" = "custom-files/hyperparameters.json"; "key" = "beta_entropy"; "dtype" = "float" }
    7  = [PSCustomObject] @{ "label" = "Modify Discount Factor"; "file" = "custom-files/hyperparameters.json"; "key" = "discount_factor"; "dtype" = "float" }
    8  = [PSCustomObject] @{ "label" = "Modify Loss Type"; "file" = "custom-files/hyperparameters.json"; "key" = "loss_type"; "dtype" = "string" }
    9  = [PSCustomObject] @{ "label" = "Modify Learning Rate"; "file" = "custom-files/hyperparameters.json"; "key" = "lr"; "dtype" = "float" }
    10 = [PSCustomObject] @{ "label" = "Modify Num of episodes between training"; "file" = "custom-files/hyperparameters.json"; "key" = "num_episodes_between_training"; "dtype" = "int" }
    11 = [PSCustomObject] @{ "label" = "Modify Num Epochs"; "file" = "custom-files/hyperparameters.json"; "key" = "num_epochs"; "dtype" = "int" }
    12 = [PSCustomObject] @{ "label" = "Modify Action Space"; "file" = "custom-files/model_metadata.json"; "key" = "action_space"; "dtype" = "array" }
    13 = [PSCustomObject] @{ "label" = "Modify Base Stack Name"; "file" = "custom-files/run.env"; "key" = "STACK"; "dtype" = "string" }
    14 = [PSCustomObject] @{ "label" = "Set New Reward Function"; "func" = "set_new_reward" }
    15 = [PSCustomObject] @{ "label" = "Add IP Access"; "func" = "add_ip" }
    16 = [PSCustomObject] @{ "label" = "Run New Training"; "func" = "run_training" }
    0  = [PSCustomObject] @{ "label" = "Quit" }
}

function Show-Menu {

    Write-Host "--- AWS Console (CLI Version) ---"
    Write-Host "---Configuration---"

    foreach ($option in $options.psobject.properties) {
        if ($option.value.file -eq "custom-files/run.env") {
            $var = Get-Variable $($option.Value.key) -ValueOnly
            Write-Output "$($option.name) - $($option.Value.label) - $var"
        }
        elseif ($option.value.file -eq "custom-files/hyperparameters.json") {
            $key = $($option.Value.key)
            Write-Output "$($option.name) - $($option.Value.label) - $($hyperparameters.$key)"
        }
        elseif ($option.value.file -eq "custom-files/model_metadata.json") {
            $key = $($option.Value.key)
            Write-Output "$($option.name) - $($option.Value.label) - $($model_metadata.$key)"
        }
        else {
            Write-Output "$($option.name) - $($option.Value.label)"
        }
    }

}

function Start-AWSTraining-old {

    Write-Output "Select Type of training:"
    Write-Output "1. New Training"
    Write-Output "2. Continue"
    $pretrained = Read-Host "Enter your choice (1-2)"

    if ($pretrained -eq 1) { $pretrained = $false }
    elseif ($pretrained -eq 2) { $pretrained = $true }
    else {
        Write-Output "Invalid Choice"
        exit
    }

    $modelname = $DR_LOCAL_S3_MODEL_PREFIX
    $pre_modelname = $DR_LOCAL_S3_PRETRAINED_PREFIX

    if ($pretrained -eq $false) {
        $i_modelname = Read-Host "Pick a name for your model (leave blank to keep current)"
        if ($i_modelname) {
            $modelname = $i_modelname
        }
        update-runEnvVariables -key "DR_LOCAL_S3_PRETRAINED" -value "False"
        update-runEnvVariables -key "DR_LOCAL_S3_MODEL_PREFIX" -value $modelname
    }
    else {
        $i_pre_modelname = Read-Host "Insert your pretrained model name (leave blank to select)"
        if (-not $i_pre_modelname) {
            $pre_modelname = $modelname
        }
        else {
            $pre_modelname = $i_pre_modelname
        }

        $modelname = Read-Host ("Pick a new name for your model: ")
        update-runEnvVariables -key "DR_LOCAL_S3_PRETRAINED" -value "True"
        update-runEnvVariables -key "DR_LOCAL_S3_MODEL_PREFIX" -value $modelname
        update-runEnvVariables -key "DR_LOCAL_S3_PRETRAINED_PREFIX" -value $pre_modelname

    }

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
        Write-Output "Inv$env:AWS_DEFAULT_PROFILE = "R619404_ADFS"
        alid Choice"
        exit
    }

    $ttl = read-host "Insert Time to live (Minutes):"

    .\create-instance.ps1 -baseResourcesStackName $STACK -stackName $modelname -timeToLiveInMinutes $ttl -machinetype $machinetype -EC2Type $standardspot


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
            "Current value of DR_LOCAL_S3_MODEL_PREFIX = $DR_LOCAL_S3_MODEL_PREFIX"
            $DR_LOCAL_S3_MODEL_PREFIX = Read-Host "Input new value for DR_LOCAL_S3_MODEL_PREFIX (keep blank for current)"
            if ($DR_LOCAL_S3_MODEL_PREFIX) {
                update-runEnvVariables -key "DR_LOCAL_S3_MODEL_PREFIX" -value $DR_LOCAL_S3_MODEL_PREFIX
            }

        } '2' {
            "Current value of DR_CAR_NAME = $DR_CAR_NAME"
            $DR_CAR_NAME = Read-Host "Input new value for DR_CAR_NAME (keep blank for current)"
            if ($DR_CAR_NAME) {
                update-runEnvVariables -key "DR_CAR_NAME" -value $DR_CAR_NAME
            }
        } '3' {
            "Current value of DR_WORLD_NAME = $DR_WORLD_NAME"
            $DR_WORLD_NAME = Read-Host "Input new value for DR_WORLD_NAME (keep blank for current)"
            if ($DR_WORLD_NAME) {
                update-runEnvVariables -key "DR_WORLD_NAME" -value $DR_WORLD_NAME
            }
        } '4' {
            "Current value of DR_RACE_TYPE = $DR_RACE_TYPE"
            $DR_RACE_TYPE = Read-Host "Input new value for DR_RACE_TYPE (keep blank for current)"
            if ($DR_RACE_TYPE) {
                update-runEnvVariables -key "DR_RACE_TYPE" -value $DR_RACE_TYPE
            }
        } '5' {
            "Current value of batch_size = $($hyperparameters.batch_size)"
            $batch_size = Read-Host "Input new value for batch_size (keep blank for current)"
            if ($batch_size) {
                update-hyperParameters -key "batch_size" -value $batch_size
            }
        } '6' {
            "Current value of beta_entropy = $($hyperparameters.beta_entropy)"
            $beta_entropy = Read-Host "Input new value for beta_entropy (keep blank for current)"
            if ($beta_entropy) {
                update-hyperParameters -key "beta_entropy" -value $beta_entropy
            }
        } '7' {
            "Current value of discount_factor = $($hyperparameters.discount_factor)"
            $discount_factor = Read-Host "Input new value for discount_factor (keep blank for current)"
            if ($discount_factor) {
                update-hyperParameters -key "discount_factor" -value $discount_factor
            }
        } '8' {
            "Current value of loss_type = $($hyperparameters.loss_type)"
            $loss_type = Read-Host "Input new value for loss_type (keep blank for current)"
            if ($loss_type) {
                update-hyperParameters -key "loss_type" -value $loss_type
            }
        } '9' {
            "Current value of lr = $($hyperparameters.lr)"
            $lr = Read-Host "Input new value for lr (keep blank for current)"
            if ($lr) {
                update-hyperParameters -key "lr" -value $lr
            }
        } '10' {
            "Current value of num_episodes_between_training = $($hyperparameters.num_episodes_between_training)"
            $num_episodes_between_training = Read-Host "Input new value for num_episodes_between_training (keep blank for current)"
            if ($num_episodes_between_training) {
                update-hyperParameters -key "num_episodes_between_training" -value $num_episodes_between_training
            }
        } '11' {
            "Current value of num_epochs = $($hyperparameters.num_epochs)"
            $num_epochs = Read-Host "Input new value for num_epochs (keep blank for current)"
            if ($num_epochs) {
                update-hyperParameters -key "num_epochs" -value $num_epochs
            }
        } '12' {
            "Current values of action_space are:"
            $model_metadata.action_space | Out-String

            $Action = Read-Host "Select Option - Add/Remove"
            if ($Action -eq "Add") {
                $key = Read-Host "Select the steering_angle to add"
                $value = Read-Host "Select the speed"

                update-actionSpace -Action $Action -key $key -value $value

            }
            elseif ($Action -eq "Remove") {
                $key = Read-Host "Select the steering_angle to Remove"
                update-actionSpace -Action $Action -key $key
            }
        } '13' {
            "Current value of STACK = $STACK"
            $STACK = Read-Host "Input new value for STACK (keep blank for current)"
            if ($STACK) {
                update-runEnvVariables -key "STACK" -value $STACK
            }
        } '14' {

        } '15' {

        }
        '16' {
            Start-AWSTraining
        }
    }
}
until ($selection -eq '0')