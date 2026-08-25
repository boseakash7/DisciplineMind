# Troubleshooting Blocked Apps Overlay

## Issue: Apps are not being blocked

### Step 1: Verify Patch Applied
```powershell
.\tools\verify_patch.ps1
```
You should see:
- ✓ FLAG_NOT_FOCUSABLE present - overlay will block apps
- ✓ unblockAndClose method found
- ✓ FLAG_NOT_TOUCH_MODAL removed - touches will work

If not, re-apply:
```powershell
.\tools\apply_block_app_patch.ps1
```

### Step 2: Check Permissions
The app needs:
1. **Overlay Permission** (SYSTEM_ALERT_WINDOW)
2. **Usage Stats Permission** (PACKAGE_USAGE_STATS)

When you create an alert, the app should request these. If not:
- Go to Android Settings → Apps → Discipline Mind → Special access
- Enable "Display over other apps"
- Enable "Usage access"

### Step 3: Check Service is Running
After creating an alert, check logs:
```powershell
flutter logs
```

You should see:
- `[AlertController] Blocked com.zerodha.kite3: true`
- `[AlertController] Blocking service started`

### Step 4: Test Blocking
1. Create a price alert (this should block apps)
2. Try opening Zerodha/Upstox/Groww
3. You should see the overlay screen

If overlay doesn't show:
- Check if apps are in blocked list: The plugin stores this in SharedPreferences
- Restart the app after granting permissions
- Check if the blocking service notification is showing (should be in notification bar)

### Step 5: Rebuild After Patch
After applying patch, you MUST rebuild:
```powershell
flutter clean
flutter pub get
.\tools\apply_block_app_patch.ps1
flutter run
```

## Issue: Unblock Button Not Working

### Check Logs
When you tap the button, you should see:
```
[BlockedAppOverlay] Button tapped!
[BlockedAppOverlay] Calling unblockAndClose...
```

If you don't see "Button tapped!":
- The overlay isn't receiving touches
- Verify patch removed FLAG_NOT_TOUCH_MODAL
- Try tapping anywhere on the screen (whole screen is tap target)

If you see "Button tapped!" but unblockAndClose fails:
- Patch wasn't applied correctly
- Re-apply patch and rebuild

## Common Issues

1. **"Apps not blocked" after patch**
   - Make sure FLAG_NOT_FOCUSABLE is present (verify_patch.ps1 will check)
   - Re-apply patch if missing

2. **"Button doesn't respond"**
   - Check FLAG_NOT_TOUCH_MODAL is removed
   - Verify patch was applied
   - Check logs for tap events

3. **"Service not starting"**
   - Check permissions are granted
   - Restart app after granting permissions
   - Check notification bar for service notification
