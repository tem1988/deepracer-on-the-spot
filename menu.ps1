function set-runEnvVariables {
    Get-Content .\custom-files\run.env | ForEach-Object {
        $pair = $_.Split("=")
        if ($pair.Length -eq 2) {
            Set-Variable -Name $pair[0] -Value  $pair[1] -Scope Script
        }
    }
}

function Show-Menu {

    Write-Host "--- AWS Console (CLI Version) ---"
    Write-Host "---Configuration---"

    Write-Output "1 - View Network ACLs Ip"
    Write-Output "2 - View Security Groups IP - no anda"
    Write-Output "3 - Add IP access"
    Write-Output "4 - Remove IP access - no anda"
    Write-Output "5 - Get Spot instance price"
    Write-Output "6 - Start Training"
    Write-Output "0 - Quit"

    $selection = Read-Host "Pick a menu item (0-5):"
    switch ($selection) {
        '1' {
            Write-Output "View Network ACLs Ip"
            .\get-IPaccess.ps1 -Type "Network ACL"
        }
        '2' {
            Write-Output "View Security Groups IP"
            .\get-IPaccess.ps1 -stackName $STACK -Type "Security Group ACL"
        }
        '3' {
            Write-Output "Add IP access"
            .\add-remove-access.ps1
        }
        '4' {
            Write-Output "Remove IP access"
            .\add-remove-access.ps1
        }
        '5' {
            get-spotPrice
        }
        '6' {
            Start-AWSTraining
        }
        '0' {
            exit
        }
    }

}

function get-spotPrice {
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
    Write-Output "1. g4dn.2xlarge"
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
        $machinetype = read-host "Write a valid instance type."
    }
    else {
        Write-Output "Invalid Choice"
        exit
    }

    $date = Get-Date -Format yyyy-MM-dd

    $global:price = aws ec2 describe-spot-price-history --instance-types $machinetype --product-description Linux/UNIX --start-time $date

    Write-Output "Latest price available:"

    ($price | ConvertFrom-Json).SpotPriceHistory[0]

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

#Main script

set-runEnvVariables

Show-Menu