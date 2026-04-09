package com.discipline.mind

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.graphics.PorterDuff
import android.graphics.drawable.GradientDrawable
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Native app blocking service - no package dependency.
 * Monitors foreground app via UsageStatsManager and shows overlay only when
 * a blocked app is on screen. Overlay hides immediately when user switches away.
 */
class AppBlockingService : Service() {
    companion object {
        private const val CHANNEL_ID = "AppBlockingServiceChannel"
        private const val NOTIFICATION_ID = 1001
        private const val CHECK_INTERVAL_MS = 50L  // Fast polling for gesture nav responsiveness
        // Launcher, recents, system UI - hide overlay when user goes home or app switcher
        private val HIDE_OVERLAY_PACKAGES = setOf(
            "com.android.launcher", "com.android.launcher2", "com.android.launcher3",
            "com.google.android.apps.nexuslauncher", "com.miui.home", "com.huawei.android.launcher",
            "com.oppo.launcher", "com.vivo.launcher", "com.samsung.android.launcher",
            "com.sec.android.app.launcher", "org.lineageos.trebuchet",
            "com.android.systemui", "com.android.quickstep"  // recents / gesture nav
        )
    }

    private val executor = Executors.newSingleThreadScheduledExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var windowManager: WindowManager
    private var flutterEngine: FlutterEngine? = null
    private var overlayView: FrameLayout? = null
    private var currentForegroundApp: String = ""
    private var overlayShowing: Boolean = false
    private var overlayShowTimeMs: Long = 0
    private var overlayPackage: String = ""
    private var lastTrackedForegroundApp: String = ""
    /** Force Unblock = one-time bypass only. Cleared when user switches away. */
    private val temporaryUnblocked = mutableSetOf<String>()
    private var lastAllowedApp: String = ""  // blocked app we're currently allowing (no overlay)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        AppManager.loadBlockedApps(applicationContext)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startAppMonitoring()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            if (it.action == "HIDE_OVERLAY") {
                mainHandler.post { hideOverlay() }
                return START_STICKY
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdownNow()
        hideOverlay()
        flutterEngine?.destroy()
        flutterEngine = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Monitors and blocks restricted apps" }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Blocking Active")
            .setContentText("Monitoring for blocked apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun getOrCreateFlutterEngine(): FlutterEngine {
        return flutterEngine ?: run {
            val loader = FlutterInjector.instance().flutterLoader()
            if (!loader.initialized()) {
                loader.startInitialization(applicationContext)
            }
            loader.ensureInitializationComplete(applicationContext, null)
            val engine = FlutterEngine(this)
            val pathToBundle = loader.findAppBundlePath()
            val overlayEntrypoint = DartExecutor.DartEntrypoint(
                pathToBundle,
                "package:discipline_mind/main_overlay.dart",
                "main"
            )
            engine.dartExecutor.executeDartEntrypoint(overlayEntrypoint)
            val methodChannel = MethodChannel(
                engine.dartExecutor.binaryMessenger,
                "com.discipline_mind/app_blocking_overlay"
            )
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "closeOverlay" -> {
                        result.success(true)
                        hideOverlay()
                    }
                    "getCurrentBlockedApp" -> result.success(currentForegroundApp)
                    "unblockAndClose" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = call.argument<List<String>>("packages")
                        if (packages != null) {
                            for (pkg in packages) {
                                AppManager.removeBlockedApp(applicationContext, pkg)
                            }
                            AppManager.loadBlockedApps(applicationContext)
                            hideOverlay()
                            stopSelf()
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packages list required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            flutterEngine = engine
            engine
        }
    }

    private fun startAppMonitoring() {
        val ourPackageName = applicationContext.packageName
        executor.scheduleAtFixedRate({
            AppManager.loadBlockedApps(applicationContext)
            val foregroundApp = getForegroundApp()
            val monitoredPackages = AppManager.getMonitoredTradingApps(applicationContext)
            if (foregroundApp != null &&
                foregroundApp != lastTrackedForegroundApp &&
                monitoredPackages.contains(foregroundApp)
            ) {
                AppUsageTracker.recordAppOpened(applicationContext, foregroundApp)
            }
            lastTrackedForegroundApp = foregroundApp ?: ""
            when {
                foregroundApp == null -> {
                    if (overlayShowing) {
                        currentForegroundApp = ""
                        mainHandler.post { hideOverlay() }
                    } else if (lastAllowedApp.isNotEmpty()) {
                        temporaryUnblocked.remove(lastAllowedApp)
                        lastAllowedApp = ""
                    }
                }
                foregroundApp != null && HIDE_OVERLAY_PACKAGES.any { foregroundApp.startsWith(it) || foregroundApp == it } -> {
                    if (overlayShowing) {
                        currentForegroundApp = ""
                        mainHandler.post { hideOverlay() }
                    } else if (lastAllowedApp.isNotEmpty()) {
                        temporaryUnblocked.remove(lastAllowedApp)
                        lastAllowedApp = ""
                    }
                }
                foregroundApp == ourPackageName -> {
                    if (overlayShowing) {
                        currentForegroundApp = ""
                        mainHandler.post { hideOverlay() }
                    } else if (lastAllowedApp.isNotEmpty()) {
                        temporaryUnblocked.remove(lastAllowedApp)
                        lastAllowedApp = ""
                    }
                }
                !AppManager.blockedApps.contains(foregroundApp) -> {
                    if (overlayShowing) {
                        currentForegroundApp = ""
                        mainHandler.post { hideOverlay() }
                    } else if (lastAllowedApp.isNotEmpty()) {
                        temporaryUnblocked.remove(lastAllowedApp)
                        lastAllowedApp = ""
                    }
                }
                foregroundApp in temporaryUnblocked -> {
                    lastAllowedApp = foregroundApp
                    if (overlayShowing) {
                        currentForegroundApp = ""
                        mainHandler.post { hideOverlay() }
                    }
                }
                else -> {
                    if (foregroundApp != currentForegroundApp || !overlayShowing) {
                        currentForegroundApp = foregroundApp
                        mainHandler.post { showOverlay(foregroundApp) }
                    }
                }
            }
        }, 0, CHECK_INTERVAL_MS, TimeUnit.MILLISECONDS)
    }

    /**
     * Get current foreground app. Uses queryEvents - only ACTIVITY_RESUMED / MOVE_TO_FOREGROUND
     * (ignore PAUSED) so minimize gestures are detected correctly. When overlay is showing,
     * use shorter window and faster polling to avoid overlay getting stuck.
     */
    private fun getForegroundApp(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            // When overlay is up, use shorter window (5s) to avoid stale PAUSED events
            val windowMs = if (overlayShowing) 5_000L else 15_000L
            val events = usm.queryEvents(time - windowMs, time)
            val usageEvent = UsageEvents.Event()
            var lastResumedPackage: String? = null
            while (events.hasNextEvent()) {
                events.getNextEvent(usageEvent)
                // Only consider RESUMED - PAUSED means app left foreground; with rapid gestures
                // we can get PAUSED for blocked app before launcher RESUMED, causing stuck overlay
                if (usageEvent.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    usageEvent.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
                ) {
                    lastResumedPackage = usageEvent.packageName
                }
            }
            if (lastResumedPackage != null) return lastResumedPackage

            // Fallback: queryUsageStats when no recent RESUMED events
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 60_000,
                time
            )
            stats
                ?.filter { it.lastTimeUsed > 0 }
                ?.maxByOrNull { it.lastTimeUsed }
                ?.packageName
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun showOverlay(packageName: String) {
        if (overlayShowing) return
        if (!AppManager.blockedApps.contains(packageName)) return
        if (packageName == applicationContext.packageName) return
        currentForegroundApp = packageName
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.OPAQUE
        ).apply {
            gravity = Gravity.CENTER
        }

        // Native overlay — matches BlockedAppOverlayPage Flutter design
        val appName = getAppDisplayName(packageName)
        val dp = resources.displayMetrics.density

        val lockIcon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
        }
        val iconSize = (80 * dp).toInt()

        val titleText = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 22f
            text = "$appName is blocked"
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }

        val msgText = TextView(this).apply {
            setTextColor(Color.argb(230, 255, 255, 255)) // white ~90%
            textSize = 14f
            text = "You have an active price alert. Stay focused on your goals."
            gravity = Gravity.CENTER
        }

        val btnBackground = GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = (8 * dp)
        }
        val forceUnblockBtn = TextView(this).apply {
            text = "Force Unblock"
            setTextColor(Color.parseColor("#DD000000")) // black87
            textSize = 15f
            gravity = Gravity.CENTER
            background = btnBackground
            setPadding((32 * dp).toInt(), (14 * dp).toInt(), (32 * dp).toInt(), (14 * dp).toInt())
            setOnClickListener { performForceUnblock() }
        }

        val nativeContent = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#DD000000")) // black87 — matches Flutter Material color
            gravity = Gravity.CENTER
            setPadding((32 * dp).toInt(), 0, (32 * dp).toInt(), 0)

            addView(lockIcon, LinearLayout.LayoutParams(iconSize, iconSize))
            addView(titleText, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = (24 * dp).toInt() })
            addView(msgText, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = (12 * dp).toInt() })
            addView(forceUnblockBtn, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = (24 * dp).toInt() })
        }
        overlayView = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#DD000000")) // black87
            addView(nativeContent, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
        }
        try {
            windowManager.addView(overlayView, params)
            overlayShowing = true
            overlayShowTimeMs = System.currentTimeMillis()
            overlayPackage = packageName
            AppUsageTracker.recordOpenedWhenBlocked(applicationContext, packageName)
        } catch (e: Exception) {
            e.printStackTrace()
            overlayShowing = false
            overlayView = null
            currentForegroundApp = ""
            return
        }

        // Native auto-unblock: check alerts API, if empty unblock (user only sees native overlay)
        executor.execute { checkAlertsAndAutoUnblock() }

        // Load Flutter behind native; swap only after first frame - no black flash
        mainHandler.post {
            if (!overlayShowing) return@post
            try {
                val engine = getOrCreateFlutterEngine()
                val flutterView = FlutterView(this)
                val container = overlayView ?: return@post
                flutterView.addOnFirstFrameRenderedListener(object : FlutterUiDisplayListener {
                    override fun onFlutterUiDisplayed() {
                        mainHandler.post {
                            if (!overlayShowing) return@post
                            container.removeAllViews()
                            container.addView(flutterView)
                        }
                    }
                    override fun onFlutterUiNoLongerDisplayed() {}
                })
                flutterView.attachToFlutterEngine(engine)
                container.addView(flutterView, 0) // Add behind native (index 0)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun checkAlertsAndAutoUnblock() {
        val userId = AppManager.loadUserIdForOverlay(applicationContext) ?: return
        try {
            val url = URL("http://api.disciplinedminds.in/api/alert/get-by-user-id")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
            conn.doOutput = true
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            conn.outputStream.use { os ->
                os.write("user_id=${java.net.URLEncoder.encode(userId, "UTF-8")}".toByteArray())
            }
            if (conn.responseCode != 200) return
            var body = conn.inputStream.bufferedReader().readText().trim()
            conn.disconnect()
            // Strip leading HTML (e.g. <br />) before parsing JSON
            val jsonStart = body.indexOf('{')
            if (jsonStart > 0) body = body.substring(jsonStart)
            val json = JSONObject(body)
            val payload = json.optJSONArray("payload") ?: return
            // Unblock only when no pending alerts (empty list or all triggered/completed)
            var hasPending = false
            for (i in 0 until payload.length()) {
                val item = payload.optJSONObject(i)
                val status = (item?.optString("status", "") ?: "").lowercase()
                if (status == "pending") {
                    hasPending = true
                    break
                }
            }
            if (!hasPending) {
                mainHandler.post { performAutoUnblock() }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getAppDisplayName(packageName: String): String {
        return when (packageName) {
            "com.zerodha.kite3" -> "Zerodha Kite"
            "in.upstox.app" -> "Upstox"
            "com.nextbillion.groww" -> "Groww"
            else -> "This app"
        }
    }

    /**
     * Auto-unblock: called when the alerts API returns empty.
     * Permanently removes all apps from the blocked list and stops the service
     * so the overlay never flashes again on next open.
     */
    private fun performAutoUnblock() {
        AppManager.getBlockedAppsList().toList().forEach { pkg ->
            AppManager.removeBlockedApp(applicationContext, pkg)
        }
        AppManager.loadBlockedApps(applicationContext)
        hideOverlay()
        stopSelf()
    }

    /** Force Unblock: one-time bypass for this app only. Next open (if alerts exist) will block again. */
    private fun performForceUnblock() {
        if (overlayPackage.isNotEmpty()) {
            temporaryUnblocked.add(overlayPackage)
            lastAllowedApp = overlayPackage
        }
        hideOverlay()
    }

    private fun hideOverlay() {
        try {
            if (overlayPackage.isNotEmpty() && overlayShowTimeMs > 0) {
                val duration = System.currentTimeMillis() - overlayShowTimeMs
                AppUsageTracker.addUsageTime(applicationContext, overlayPackage, duration)
            }
            overlayPackage = ""
            overlayShowTimeMs = 0
            overlayView?.let {
                try {
                    windowManager.removeView(it)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                overlayView = null
            }
            overlayShowing = false
            currentForegroundApp = ""
            flutterEngine?.destroy()
            flutterEngine = null
        } catch (e: Exception) {
            e.printStackTrace()
            overlayShowing = false
            overlayView = null
            currentForegroundApp = ""
        }
    }
}
