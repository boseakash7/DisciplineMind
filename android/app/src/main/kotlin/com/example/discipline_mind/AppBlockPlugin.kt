package com.discipline.mind

import android.app.AppOpsManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native app blocking - handles block/unblock and permissions.
 * No external package dependency.
 */
class AppBlockPlugin(private val activity: android.app.Activity) : MethodChannel.MethodCallHandler {

    fun attachTo(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.discipline_mind/app_block_manager")
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = activity.applicationContext
        when (call.method) {
            "blockApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    AppManager.blockApp(ctx, packageName)
                    result.success(true)
                } else {
                    result.error("ERROR", "packageName required", null)
                }
            }
            "unblockApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    AppManager.unblockApp(ctx, packageName)
                    result.success(true)
                } else {
                    result.error("ERROR", "packageName required", null)
                }
            }
            "getBlockedApps" -> {
                result.success(AppManager.getBlockedAppsList())
            }
            "isAppBlocked" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(AppManager.isAppBlocked(packageName))
                } else {
                    result.error("ERROR", "packageName required", null)
                }
            }
            "startBlockingService" -> {
                AppManager.startBlockingService(ctx)
                result.success(true)
            }
            "stopBlockingService" -> {
                AppManager.stopBlockingService(ctx)
                result.success(true)
            }
            "checkPermissions" -> {
                result.success(mapOf(
                    "hasOverlayPermission" to isOverlayPermissionGranted(),
                    "hasUsageStatsPermission" to isUsageStatsEnabled()
                ))
            }
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(true)
            }
            "requestUsageStatsPermission" -> {
                requestUsageStatsPermission()
                result.success(true)
            }
            "saveUserIdForOverlay" -> {
                val userId = call.argument<String>("userId")
                if (userId != null) {
                    AppManager.saveUserIdForOverlay(ctx, userId)
                    result.success(true)
                } else {
                    result.error("ERROR", "userId required", null)
                }
            }
            "getBlockedAppUsageStats" -> {
                val packages = listOf(
                    "com.zerodha.kite3",
                    "in.upstox.app",
                    "com.nextbillion.groww"
                )
                val list = AppUsageTracker.getAllUsage(ctx, packages)
                result.success(list.map { mapOf(
                    "packageName" to it["packageName"],
                    "openCount" to it["openCount"],
                    "openedWhenBlockedCount" to it["openedWhenBlockedCount"],
                    "usageTimeMs" to it["usageTimeMs"]
                ) })
            }
            else -> result.notImplemented()
        }
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(activity)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${activity.packageName}")
            )
            activity.startActivityForResult(intent, 1234)
        }
    }

    private fun isUsageStatsEnabled(): Boolean {
        val appOps = activity.getSystemService(android.content.Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                activity.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                activity.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        activity.startActivityForResult(intent, 1237)
    }
}
