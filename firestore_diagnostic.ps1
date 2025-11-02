# Firestore Permission-Denied Diagnostic
$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== Firestore Permission-Denied Diagnostic ===" -ForegroundColor Green
Write-Host ""

# Get project ID
function Get-ProjectId {
  $candidates = @(
    "android\app\google-services.json",
    "ios\Runner\GoogleService-Info.plist", 
    "web\firebase-config.js",
    "lib\firebase_options.dart"
  )
  foreach($p in $candidates){
    if(Test-Path $p){
      $txt = Get-Content $p -Raw
      if($p -like "*.json"){
        try{
          $j = $txt | ConvertFrom-Json
          if($j.project_info.project_id){ return $j.project_info.project_id }
        }catch{}
      }
      if($p -like "*firebase_options.dart"){
        if($txt -match "projectId:\s*'([^']+)'"){ return $Matches[1] }
      }
    }
  }
  return $null
}

$projectId = Get-ProjectId
Write-Host "ProjectId: " + ($(if($projectId){$projectId}else{"(not found)"}))

# Check tools
function ToolExists($name){ return [bool](Get-Command $name -ErrorAction SilentlyContinue) }
$hasNode = ToolExists "node"
$hasNpm = ToolExists "npm" 
$hasFb = ToolExists "firebase"

Write-Host "Node: " + ($(if($hasNode){"OK"}else{"Not Found"}))
Write-Host "npm : " + ($(if($hasNpm){"OK"}else{"Not Found"}))
Write-Host "CLI : " + ($(if($hasFb){"OK"}else{"Not Found"}))
Write-Host ""

# Analyze rules
$rulesPath = "firestore.rules"
$rules = ""
$rulesFound = Test-Path $rulesPath
if($rulesFound){ $rules = Get-Content $rulesPath -Raw }

$expectsOwnerOnCreate = @()
if($rules){
  if($rules -match "request\.resource\.data\.ownerUid"){ $expectsOwnerOnCreate += "ownerUid" }
  if($rules -match "request\.resource\.data\.sheikhUid"){ $expectsOwnerOnCreate += "sheikhUid" }
  if($rules -match "request\.resource\.data\.sheikhId"){ $expectsOwnerOnCreate += "sheikhId" }
}

$requiresCreatedBy = $false
if($rules -match "request\.resource\.data\.createdBy\s*==\s*request\.auth\.uid"){ $requiresCreatedBy = $true }

$requiresRoleSheikh = $false
if($rules -match "role\s*==\s*""sheikh"""){ $requiresRoleSheikh = $true }

Write-Host "Rules: " + ($(if($rulesFound){"FOUND"}else{"NOT FOUND"}))
if($rulesFound){
  Write-Host " - Owner fields on CREATE: " + ($(if($expectsOwnerOnCreate.Count){$expectsOwnerOnCreate -join ", "}else{"(none found)"}))
  Write-Host " - Requires createdBy? " + $requiresCreatedBy
  Write-Host " - Requires role==sheikh? " + $requiresRoleSheikh
}
Write-Host ""

# Analyze Dart code
$dartFiles = @(Get-ChildItem -Recurse -Include *.dart -ErrorAction SilentlyContinue)
$ownerKeysInApp = New-Object System.Collections.Generic.HashSet[string]
$createdByInApp = $false
$collectionNames = New-Object System.Collections.Generic.HashSet[string]

foreach($f in $dartFiles){
  $t = Get-Content $f.FullName -Raw
  foreach($m in ([regex]::Matches($t, "collection\(\s*['""]([^'""]+)['""]\s*\)"))){
    $collectionNames.Add($m.Groups[1].Value) | Out-Null
  }
  if($t -match "ownerUid"){ $ownerKeysInApp.Add("ownerUid") | Out-Null }
  if($t -match "sheikhUid"){ $ownerKeysInApp.Add("sheikhUid") | Out-Null }
  if($t -match "sheikhId"){ $ownerKeysInApp.Add("sheikhId") | Out-Null }
  if($t -match "createdBy"){ $createdByInApp = $true }
}

Write-Host "App owner fields used: " + ($(if($ownerKeysInApp.Count){ ($ownerKeysInApp.ToArray() -join ", ") }else{"(none found)"}))
Write-Host "App sets createdBy? " + $createdByInApp
Write-Host "Collections in code: " + ($(if($collectionNames.Count){ ($collectionNames.ToArray() -join ", ") }else{"(none found)"}))
Write-Host ""

# Check for mismatches
$ownerMismatch = $false
if($expectsOwnerOnCreate.Count -gt 0 -and $ownerKeysInApp.Count -gt 0){
  $intersection = $expectsOwnerOnCreate | Where-Object { $ownerKeysInApp.Contains($_) }
  if(($intersection | Measure-Object).Count -eq 0){
    $ownerMismatch = $true
  }
}

$createdByMismatch = $false
if($requiresCreatedBy -and -not $createdByInApp){ $createdByMismatch = $true }

# Final report
Write-Host "=== Diagnostic Summary ===" -ForegroundColor Yellow
$issues = @()

if(-not $rulesFound){ $issues += "Rules file not found locally" }
if($ownerMismatch){ $issues += "Owner field mismatch between rules and code" }
if($createdByMismatch){ $issues += "createdBy missing in code but required by rules" }
if($requiresRoleSheikh){ $issues += "Rules require role==sheikh - check users/{uid} document" }
if(-not $hasNode -or -not $hasNpm){ $issues += "node/npm not found (needed for CLI deployment)" }

if($issues.Count -eq 0){
  Write-Host "No obvious local mismatches detected." -ForegroundColor Green
  Write-Host "Likely issues: Rules not published, Auth session expired, or users/{uid}.role not set"
}else{
  $i=1
  foreach($x in $issues){
    Write-Host "[$i] $x" -ForegroundColor Red
    $i++
  }
}

# Root cause analysis
$root = ""
if($ownerMismatch){ $root = "Most likely cause: Owner field mismatch between rules and code" }
elseif($createdByMismatch){ $root = "Most likely cause: Rules require createdBy but code doesn't set it" }
elseif($requiresRoleSheikh){ $root = "Possible cause: Rules require role==sheikh but user document missing this field" }
else{ $root = "Cannot determine cause from local files; check rule deployment and user authentication" }

Write-Host ""
Write-Host "=> $root" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green

