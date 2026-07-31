package com.discipline.mind

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
        // Cold start: restore blocked list and start monitor before Flutter is ready.
        // Previously Flutter called startBlockingService before the MethodChannel existed,
        // so first launch often never started the service.
        try {
            AppManager.loadBlockedApps(this)
            if (AppManager.blockedApps.isNotEmpty()) {
                AppManager.startBlockingService(this)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
