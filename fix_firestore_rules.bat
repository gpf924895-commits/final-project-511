@echo off
echo ========================================
echo FIREBASE FIRESTORE RULES FIX
echo ========================================
echo.
echo The permission error you're seeing is caused by incorrect Firestore rules.
echo I've prepared the correct rules for you.
echo.
echo FOLLOW THESE STEPS TO FIX:
echo.
echo 1. Open this URL in your browser:
echo    https://console.firebase.google.com/project/mohathrahapp/firestore/rules
echo.
echo 2. Replace ALL the existing rules with this content:
echo.
echo ========================================
echo COPY THE RULES BELOW:
echo ========================================
echo.
type firestore.rules
echo.
echo ========================================
echo.
echo 3. Click "Publish" button
echo 4. Wait for deployment confirmation
echo 5. Test your app - the error should be gone!
echo.
echo ========================================
echo.
echo Opening Firebase Console for you...
start https://console.firebase.google.com/project/mohathrahapp/firestore/rules
echo.
echo Press any key to continue...
pause >nul
