python -m py_compile custom-files/reward_function.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "error in reward_function.py"
    exit 1
}

try {
    Get-Content .\custom-files\model_metadata.json | ConvertFrom-Json -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "error in model_metadata.json"
    exit 1
}

try {
    Get-Content .\custom-files\hyperparameters.json | ConvertFrom-Json -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "error in hyperparameters.json"
    exit 1
}

#track exists
#Get-Content .\custom-files\run.env | ForEach-Object {
#    $pair = $_.Split("=")
#    if ($pair.Length -eq 2) {
#        Set-Variable -Name $pair[0] -Value  $pair[1] -Scope Script
#    }
#}

$tracks = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/aws-deepracer-community/deepracer-race-data/contents/raw_data/tracks/npy"
$tracks = $tracks | Select-Object -ExpandProperty name

$DR_WORLD_NAME_NPY = $DR_WORLD_NAME + ".npy"

if ($DR_WORLD_NAME_NPY -notin $tracks) {
    Write-Output "DR_WORLD_NAME=$DR_WORLD_NAME TRACK IN run.env DOES NOT EXIST. VALID TRACKS ARE $tracks"
    exit 1
}

#race type exists
$allowedracetypes = @("TIME_TRIAL", "OBJECT_AVOIDANCE", "HEAD_TO_BOT")

if ($DR_RACE_TYPE -notin $allowedracetypes) {
    Write-Output "DR_RACE_TYPE=$DR_RACE_TYPE in run.env DOES MATCH THE ALLOWED RACE TYPES $allowedracetypes"
    exit 1
}


#color exists
$colors = @("Black", "Grey", "Blue", "Red", "Orange", "White", "Purple")
if ($DR_CAR_COLOR -notin $colors) {
    Write-Output "DR_CAR_COLOR=$DR_CAR_COLOR in run.env DOES MATCH THE ALLOWED COLOR TYPES $colors"
    exit 1
}

$model = aws s3 ls s3://${BUCKET}/${DR_LOCAL_S3_MODEL_PREFIX}
if ($model) {
    Write-Output "model ${DR_LOCAL_S3_MODEL_PREFIX} alread exists in ${BUCKET}. Change the model name DR_LOCAL_S3_MODEL_PREFIX in run.env"
    exit 1
}

#check if pretrained model exists in bucket
if ($DR_LOCAL_S3_PRETRAINED -eq "True") {
    $pretrainmodel = aws s3 ls s3://${BUCKET}/${DR_LOCAL_S3_PRETRAINED_PREFIX}
    if (-not $pretrainmodel) {
        Write-Output "pretrained model DR_LOCAL_S3_PRETRAINED_PREFIX=${DR_LOCAL_S3_PRETRAINED_PREFIX} doesn't exist in ${BUCKET}."
        exit 1
    }
}

exit 0