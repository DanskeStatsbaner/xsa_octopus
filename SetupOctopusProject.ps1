﻿Param (
$fromProjectName,
$toProjectName,
$octopusURL,
$octopusAPIKey
)
$ErrorActionPreference = "Stop";

# Define working variables - extended header

$header = @{ "X-Octopus-ApiKey" = $octopusAPIKey ; "Cache-Control"="no-cache"; "accept"="application/json"; "content-type" = "application/json"}
$spaceName = "DataArten"
$lifeCycleName = "sit-dev-tst-prd"

if ((($toProjectName.Substring(0,1)).ToUpper() -eq 'C')){
$toProjectGroupName = "CF-containers"
} elseif ((($toProjectName.Substring(0,1)).ToUpper() -eq 'P')) {
$toProjectGroupName = "P-containers"
} elseif  ((($toProjectName.Substring(0,1)).ToUpper() -eq 'S')) {
$toProjectGroupName = "SI-containers"
} elseif  ((($toProjectName.Substring(0,1)).ToUpper() -eq 'A')) {
$toProjectGroupName = "AP-containers"
} else {
$toProjectGroupName = "SteamTeam"
}

# Get space
$space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}

# Get fromProject
$fromProjectList = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/projects/all" -Headers $header)  | Where-Object {$_.Name -eq $fromProjectName}

if ($fromProjectList.Name -ne $fromProjectName)
{
    Write-Host "$fromProjectName is not found"
    return    
}

# Get fromProject deployment process
foreach ($fromProject in $fromProjectList)
{
    $fromDeploymentProcess = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/deploymentprocesses/$($fromProject.DeploymentProcessId)" -Headers $header)
}

# Get toProject
$toProjectList = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/projects/all" -Headers $header)  | Where-Object {$_.Name -eq $toProjectName}

# Create toProject if it does not exist
if ($toProjectList.Name -ne $toProjectName)
{
    # Get project group
    $toProjectGroup = (Invoke-RestMethod -Method Get "$octopusURL/api/$($space.Id)/projectgroups/all" -Headers $header) | Where-Object {$_.Name -eq $toProjectGroupName}

    # Get Lifecycle
    $lifeCycle = (Invoke-RestMethod -Method Get "$octopusURL/api/$($space.Id)/lifecycles/all" -Headers $header) | Where-Object {$_.Name -eq $lifecycleName}

    $jsonPayload = @{
                     Name = $toProjectName
                     Description = $toProjectName
                     ProjectGroupId = $toProjectGroup.Id
                     LifeCycleId = $lifeCycle.Id
                    }

    # Create project
    $toProjectList = (Invoke-RestMethod -Method Post -Uri "$octopusURL/api/$($space.Id)/projects" -Body ($jsonPayload | ConvertTo-Json -Depth 10) -Headers $header)
}

# Get toProject deployment process
foreach ($toProject in $toProjectList)
{
    $toDeploymentProcess = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/deploymentprocesses/$($toProject.DeploymentProcessId)" -Headers $header)
    $toDeploymentProcess.Steps = $fromDeploymentProcess.Steps
    $updateProject = (Invoke-RestMethod -Method Put -Uri "$octopusURL/api/$($space.Id)/deploymentprocesses/$($toProject.DeploymentProcessId)" -Body ($toDeploymentProcess | ConvertTo-Json -Depth 10) -Headers $header)
}

# Get Variable sets
$librarySet = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/libraryvariablesets/all" -Headers $header) | Where-Object {$_.Name -eq "ArtifactoryDocker"}
$toProject.IncludedLibraryVariableSetIds += $librarySet.Id
$librarySet = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/libraryvariablesets/all" -Headers $header) | Where-Object {$_.Name -eq "dataART"}
$toProject.IncludedLibraryVariableSetIds += $librarySet.Id

$updateProject = (Invoke-RestMethod -Method Put -Uri "$octopusURL/api/$($space.Id)/projects/$($toProject.Id)" -Body ($toProject | ConvertTo-Json -Depth 10) -Headers $header)
