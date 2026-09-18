package com.discipline.mind

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import android.app.Application
import io.flutter.embedding.engine.loader.FlutterLoader

/**
 * Ensures FlutterLoader is initialized before AppBlockingService runs.
 * Required so the overlay engine can create FlutterEngine when a blocked app is opened.
 */
class DisciplineApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FlutterLoader().apply {
            startInitialization(this@DisciplineApplication)
            ensureInitializationComplete(this@DisciplineApplication, null)
        }
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val defaultChannel = NotificationChannel(
            "zeno_ai_alerts",
            "Price Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Notifications for price alerts"
        }
        notificationManager.createNotificationChannel(defaultChannel)

        val soundResourceId = resources.getIdentifier(
            "trade_opportunity",
            "raw",
            packageName,
        )
        val soundUri = Uri.parse("android.resource://$packageName/$soundResourceId")
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()

        listOf(
            "zeno_ai_trade_opportunities",
            // Backend/Phase 4 channel id still used by some notification payloads.
            "discipline_mind_trade_opportunities",
        ).forEach { channelId ->
            val tradeChannel = NotificationChannel(
                channelId,
                "Trade Opportunities",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notifications for new trade opportunities"
                if (soundResourceId != 0) {
                    setSound(soundUri, audioAttributes)
                }
            }
            notificationManager.createNotificationChannel(tradeChannel)
            Log.d(
                "NotificationSound",
                "Created channel=$channelId soundResourceId=$soundResourceId " +
                    "sound=trade_opportunity",
            )
        }
    }
}
