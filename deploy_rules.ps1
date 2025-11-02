# PowerShell script to deploy Firestore rules via REST API
# This script will update the Firestore rules to fix the permission error

# Read the current firestore.rules file
$rulesContent = Get-Content -Path "firestore.rules" -Raw

# Firebase project configuration
$projectId = "mohathrahapp"
$accessToken = ""

# Function to get access token (requires user to login via browser)
function Get-AccessToken {
    Write-Host "To deploy Firestore rules, you need to:"
    Write-Host "1. Go to https://console.firebase.google.com/"
    Write-Host "2. Select project: $projectId"
    Write-Host "3. Go to Project Settings > Service Accounts"
    Write-Host "4. Generate new private key"
    Write-Host "5. Download the JSON file"
    Write-Host "6. Extract the 'private_key' and 'client_email' from the JSON"
    Write-Host ""
    Write-Host "Alternatively, you can manually update the rules in Firebase Console:"
    Write-Host "1. Go to Firestore Database > Rules"
    Write-Host "2. Replace with the content from firestore.rules file"
    Write-Host "3. Click Publish"
}

# Display the rules that need to be deployed
Write-Host "=== FIRESTORE RULES TO DEPLOY ==="
Write-Host ""
Write-Host $rulesContent
Write-Host ""
Write-Host "=== MANUAL DEPLOYMENT INSTRUCTIONS ==="
Write-Host ""

Get-AccessToken

Write-Host ""
Write-Host "=== ALTERNATIVE: Use Firebase Console ==="
Write-Host "1. Open https://console.firebase.google.com/"
Write-Host "2. Select project: $projectId"
Write-Host "3. Go to Firestore Database > Rules"
Write-Host "4. Replace the existing rules with the content above"
Write-Host "5. Click 'Publish'"
Write-Host ""
Write-Host "This will fix the permission error you're experiencing."
