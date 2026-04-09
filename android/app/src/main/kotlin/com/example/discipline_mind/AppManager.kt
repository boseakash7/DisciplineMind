package com.discipline.mind

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

/**
 * Native app blocking storage - no package dependency.
 * Stores blocked app package names in SharedPreferences.
 */
object AppManager {
    private const val PREFS_NAME = "AppBlockingPrefs"
    private const val BLOCKED_APPS_KEY = "blockedApps"
    private const val MONITORED_APPS_KEY = "monitoredTradingApps"
    private const val USER_ID_KEY = "userIdForOverlay"

    fun saveUserIdForOverlay(context: Context, userId: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putString(USER_ID_KEY, userId).apply()
    }

    fun loadUserIdForOverlay(context: Context): String? {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(USER_ID_KEY, null)
    }

    var blockedApps: MutableSet<String> = mutableSetOf()
        private set

    fun loadBlockedApps(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val loaded = prefs.getStringSet(BLOCKED_APPS_KEY, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        blockedApps.clear()
        blockedApps.addAll(loaded)
    }

    private fun saveBlockedApps(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(BLOCKED_APPS_KEY, blockedApps).apply()
    }

    fun addBlockedApp(context: Context, packageName: String) {
        if (blockedApps.add(packageName)) {
            saveBlockedApps(context)
        }
    }

    fun removeBlockedApp(context: Context, packageName: String) {
        if (blockedApps.remove(packageName)) {
            saveBlockedApps(context)
        }
    }

    fun blockApp(context: Context, packageName: String) {
        blockedApps.add(packageName)
        saveBlockedApps(context)
        startBlockingService(context)
    }

    fun unblockApp(context: Context, packageName: String) {
        blockedApps.remove(packageName)
        saveBlockedApps(context)
        if (blockedApps.isEmpty()) {
            stopBlockingService(context)
        }
    }

    fun isAppBlocked(packageName: String): Boolean = blockedApps.contains(packageName)

    fun startBlockingService(context: Context) {
        val intent = Intent(context, AppBlockingService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun stopBlockingService(context: Context) {
        val intent = Intent(context, AppBlockingService::class.java)
        context.stopService(intent)
    }

    fun getBlockedAppsList(): List<String> = blockedApps.toList()

    fun saveMonitoredTradingApps(context: Context, packages: List<String>) {
        val cleaned = packages
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toSet()
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(MONITORED_APPS_KEY, cleaned)
            .apply()
    }

    fun getMonitoredTradingApps(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val stored = prefs.getStringSet(MONITORED_APPS_KEY, null)
        if (stored != null && stored.isNotEmpty()) return stored
        // Safe fallback until API list is synced from Flutter.
        return setOf(
            "com.zerodha.kite3",
            "in.upstox.app",
            "com.nextbillion.groww"
        )
    }
}
