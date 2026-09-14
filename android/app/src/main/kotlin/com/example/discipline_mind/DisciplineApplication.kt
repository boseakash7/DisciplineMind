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
    }
}
