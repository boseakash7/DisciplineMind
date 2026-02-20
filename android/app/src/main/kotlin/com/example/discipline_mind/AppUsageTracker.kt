package com.discipline.mind

import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * Tracks usage of blocked apps (Zerodha, Upstox, Groww):
 * - openCount: total times app was opened (from UsageStats - works when blocked or not)
 * - openedWhenBlockedCount: times user opened when app was blocked (our tracking)
 * - usageTimeMs: time when blocked (our tracking)
 * - totalUsageTimeMs: total time in app from Android (works when blocked or not)
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
        val openedWhenBlocked = json.optInt("openedWhenBlockedCount", 0)
        val usageWhenBlocked = json.optLong("usageTimeMs", 0)

        var totalOpens = 0
        var totalUsageMs = 0L
        try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 30L * 24 * 60 * 60 * 1000 // 30 days

            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, beginTime, endTime)
            val pkgStats = stats?.filter { it.packageName == packageName }
            totalUsageMs = pkgStats?.sumOf { it.totalTimeInForeground } ?: 0L

            val events = usm.queryEvents(beginTime, endTime)
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.packageName == packageName &&
                    (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                     event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND)) {
                    totalOpens++
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return mapOf(
            "packageName" to packageName,
            "openCount" to totalOpens,
            "openedWhenBlockedCount" to openedWhenBlocked,
            "usageTimeMs" to usageWhenBlocked,
            "totalUsageTimeMs" to totalUsageMs
        )
    }

    fun getAllUsage(context: Context, packages: List<String>): List<Map<String, Any>> {
        return packages.map { getUsageForPackage(context, it) }
    }
}
