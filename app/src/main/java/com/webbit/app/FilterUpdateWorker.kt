package com.webbit.app

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.webbit.app.adblock.FilterListManager

class FilterUpdateWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        return try {
            val manager = FilterListManager(applicationContext)
            manager.updateLists()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
