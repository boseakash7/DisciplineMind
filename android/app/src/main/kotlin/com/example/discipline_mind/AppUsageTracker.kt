package com.discipline.mind

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * Tracks usage of blocked apps (Zerodha, Upstox, Groww):
 * - openCount: times user opened the app
 * - openedWhenBlockedCount: times user opened when app was blocked
 * - usageTimeMs: total time user spent with blocked app in foreground (overlay visible)
 */
object AppUsageTracker {
    private const val PREFS_NAME = "AppUsageTrackerPrefs"
    private const val KEY_PREFIX = "usage_"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun recordAppOpened(context: Context, packageName: String) {
        val p = prefs(context)
        val key = KEY_PREFIX + packageName
        val json = JSONObject(p.getString(key, "{}") ?: "{}")
        json.put("openCount", json.optInt("openCount", 0) + 1)
        p.edit().putString(key, json.toString()).apply()
    }

    fun recordOpenedWhenBlocked(context: Context, packageName: String) {
        val p = prefs(context)
        val key = KEY_PREFIX + packageName
        val json = JSONObject(p.getString(key, "{}") ?: "{}")
        json.put("openedWhenBlockedCount", json.optInt("openedWhenBlockedCount", 0) + 1)
        p.edit().putString(key, json.toString()).apply()
    }

    fun addUsageTime(context: Context, packageName: String, durationMs: Long) {
        val p = prefs(context)
        val key = KEY_PREFIX + packageName
        val json = JSONObject(p.getString(key, "{}") ?: "{}")
        json.put("usageTimeMs", json.optLong("usageTimeMs", 0) + durationMs)
        p.edit().putString(key, json.toString()).apply()
    }

    fun getUsageForPackage(context: Context, packageName: String): Map<String, Any> {
        val p = prefs(context)
        val json = JSONObject(p.getString(KEY_PREFIX + packageName, "{}") ?: "{}")
        return mapOf(
            "packageName" to packageName,
            "openCount" to json.optInt("openCount", 0),
            "openedWhenBlockedCount" to json.optInt("openedWhenBlockedCount", 0),
            "usageTimeMs" to json.optLong("usageTimeMs", 0)
        )
    }

    fun getAllUsage(context: Context, packages: List<String>): List<Map<String, Any>> {
        return packages.map { getUsageForPackage(context, it) }
    }
}
