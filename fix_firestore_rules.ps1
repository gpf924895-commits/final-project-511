# Auto Fix Firestore Rules
$p = "firestore.rules"
if (-Not (Test-Path $p)) {
  Write-Host "File firestore.rules not found in current folder."
  exit
}

$c = Get-Content $p -Raw
if ($c -match "sheikhUid") {
  $n = $c -replace "sheikhUid", "sheikhId"
  Set-Content -Path $p -Value $n -Encoding UTF8
  Write-Host "Replaced sheikhUid to sheikhId"
} else {
  Write-Host "Already correct (no sheikhUid found)."
}

if (Get-Command firebase -ErrorAction SilentlyContinue) {
  Write-Host "Deploying updated rules..."
  firebase deploy --only firestore:rules
  Write-Host "Firestore rules deployed successfully!"
} else {
  Write-Host "Firebase CLI not found."
  Write-Host "Run this to install it:"
  Write-Host "npm install -g firebase-tools"
  Write-Host "Then rerun this script."
}
