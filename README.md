# discipline_mind

A new Flutter project.

## Blocked-app overlay (Android)

When a blocked app (Zerodha, Upstox, Groww) is opened, the app checks **Firebase Remote Config** to decide whether to keep apps blocked or unblock.

### Firebase Remote Config (for testing)

1. **Firebase Console** → your project → **Remote Config**.
2. Add a parameter:
   - **Parameter key:** `should_block_trading_apps`
   - **Data type:** Boolean
   - **Default value:** `true` (keep blocked) or `false` (unblock)
3. **Publish changes**. Toggle the value to test:
   - `true` → overlay stays, apps remain blocked
   - `false` → apps are unblocked and overlay closes

Run `flutter pub get` (adds `firebase_remote_config`).

### Patch (for overlay + unblock to work):

1. **Apply the patch** after `flutter pub get`:
   ```powershell
   .\tools\apply_block_app_patch.ps1
   ```

2. **Verify the patch** was applied:
   ```powershell
   .\tools\verify_patch.ps1
   ```
   You should see green checkmarks. If you see warnings, re-apply the patch.

3. **Rebuild the app**:
   ```powershell
   flutter run
   ```

### Troubleshooting:

- **Button not responding?** 
  - Check logs: `flutter logs` - you should see `[BlockedAppOverlay] Button tapped!` when you tap
  - Verify patch: Run `.\tools\verify_patch.ps1`
  - Re-apply patch: `.\tools\apply_block_app_patch.ps1` then rebuild

- **Patch not applying?**
  - Make sure you ran `flutter pub get` first
  - Check the path in the script matches your pub cache location

## Getting Started
https://developer.apple.com/contact/request/family-controls-distribution
This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
