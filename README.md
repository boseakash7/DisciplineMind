# discipline_mind

A new Flutter project.

## Mind Control Guard (iOS)

After consent, Screen Time authorization, and selecting the actual broker in
Apple's app picker, the guard keeps the selected apps shielded all day, including
weekends. Permission alone does not select or shield an app. Existing installations
must open Zeno once after updating to restore the saved selection and remove the
old market-hours schedules.

The shield uses Apple's native layout with the guard icon, status, message, and
buttons. iOS does not support displaying the Flutter overlay from Android above
another app. The small “Zeno AI” return link in the status bar is not a shield.

Opening a broker from Zeno's chat applies the native shield before launching
the broker URL. It does not present the Flutter guard or grant temporary access.
The preserved Flutter screen is not used in this launch path. Temporary Skip
access is granted by the native shield's secondary button.

The app, shield action extension, and activity monitor use the same named Managed
Settings store (`zeno-mind-control-guard`) on iOS 16 and later. Applying a guard
migrates legacy default-store shields after configuring the shared store. On iOS
26.5 and later, the store is explicitly activated and saved application tokens
are refreshed on enable (best effort, with the outcome recorded in diagnostics).
`configuredShieldAppCount` reports configured settings, not proof that iOS has
displayed a shield; `shieldConfigInvokedAt` records actual configuration calls.
If direct Home Screen launches bypass the guard despite configured tokens, turn
off Zeno's access under iPhone Settings > Screen Time > Apps with Screen Time
Access, then grant access and reselect the broker in Zeno's settings. Direct Home Screen and force-close enforcement remain unverified following
reports that only the Flutter pre-launch screen appeared. Device testing must
verify the native shield independently. Trade completion and alert deletion grant
temporary access rather than disabling the saved guard.

“SKIP (1 MIN)” grants the selected broker one minute of usage. A Device Activity
event restores its shield without needing Zeno to open again; a non-repeating
16-minute schedule restores it at interval end if the usage threshold is not
reached. iOS controls callback delivery, so restoration timing may vary. Opening
Zeno also ends temporary access. Monitoring is registered before unshielding; if
registration fails the broker stays shielded. Only one temporary exemption is
active at a time. Before iOS 17.4, the usage event may include earlier activity.

“I WILL CONTROL” opens Zeno on iOS 26.5 or later; on earlier versions, it closes
the broker and queues the chat for the next time Zeno opens. iOS provides no
broker-exit callback: reopening the broker during temporary access does not show
a new guard. After access expires, subsequent launches show the shield again.

Verify with a signed build on a physical iPhone (Family Controls and the shared
App Group must be provisioned for the app and its extensions): enable the guard,
open the selected broker from its own icon, use SKIP, and use it for one minute
without opening Zeno. Confirm the shield returns, then repeat the Skip cycle.
Also test skipping and leaving the broker idle until the monitoring interval
ends. Repeat outside market hours and after terminating Zeno. Verify Skip stays
blocked if monitoring registration fails and stale callbacks from an earlier Skip
do not cancel a later one.
Confirm that deselected apps remain accessible and disabling the guard removes
the restriction.

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

### Android ZIP reference and iOS policy

The supplied `android 1.zip` was compared without replacing Android sources.
iOS syncs the same v2test `app/state` decision on startup and Zeno broker launches.
Enabled native protection takes priority over a server `unlocked` response;
native Skip remains a separate temporary allowance. Re-enabling protection
repairs the saved priority flag left by older unblock/re-enable paths.

`ios/ShieldConfiguration/GuardOpenReporter.swift` performs best-effort reporting
when iOS requests an app shield configuration. It fetches `app/state`, then posts
`app/force-unlock` with `user_id` and `trade_id` only for a confirmed blocking
state with a nonempty trade ID. Both endpoints use the Android v2test base URL.
Requests have an eight-second timeout and a per-user/app 30-second cooldown to
suppress redraw duplicates. Reporting does not change the local shield policy.
Diagnostic status is saved as `guardOpenReportStatus` in the shared app group.

This is not Android foreground polling or exact per-open tracking. iOS can cache
shield configurations or terminate the extension before networking completes;
delivery is not guaranteed. If the shield extension is not invoked, no report is
sent. Native enforcement and live API delivery still require physical-device
verification independently of a successful build.

Native reporter tests (mock networking; no production requests):
```sh
swiftc ios/ShieldConfiguration/GuardOpenReporter.swift test/native/guard_open_reporter_test.swift -o /tmp/guard-reporter-test
/tmp/guard-reporter-test
```
