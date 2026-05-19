package com.webbit.app

import android.app.Application
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class WebbitApp : Application() {
    override fun onCreate() {
        super.onCreate()
        scheduleFilterUpdates()
    }

    private fun scheduleFilterUpdates() {
        val request = PeriodicWorkRequestBuilder<FilterUpdateWorker>(
            24, TimeUnit.HOURS
        ).build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "filter_update",
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }
}
