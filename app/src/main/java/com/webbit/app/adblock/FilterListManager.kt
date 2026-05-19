package com.webbit.app.adblock

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.concurrent.TimeUnit

class FilterListManager(private val context: Context) {

    data class FilterListSource(
        val name: String,
        val url: String,
        val enabled: Boolean = true,
    )

    companion object {
        val DEFAULT_SOURCES = listOf(
            FilterListSource("uBlock-filters", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"),
            FilterListSource("uBlock-privacy", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"),
            FilterListSource("uBlock-quick-fixes", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt"),
            FilterListSource("uBlock-unbreak", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt"),
        )

        private const val CACHE_DIR = "filter_lists"
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    suspend fun updateLists(
        sources: List<FilterListSource> = DEFAULT_SOURCES,
        onProgress: (String) -> Unit = {},
    ): List<FilterRule> {
        return withContext(Dispatchers.IO) {
            val allRules = mutableListOf<FilterRule>()
            for (source in sources) {
                if (!source.enabled) continue
                try {
                    onProgress("Downloading ${source.name}...")
                    val body = downloadList(source.url)
                    onProgress("Parsing ${source.name}...")
                    val rules = parseList(body)
                    allRules.addAll(rules)
                    cacheList(source.name, body)
                } catch (e: Exception) {
                    onProgress("Cached ${source.name}")
                    val cached = loadCached(source.name)
                    if (cached != null) {
                        allRules.addAll(parseList(cached))
                    }
                }
            }
            onProgress("Loaded ${allRules.size} rules")
            allRules
        }
    }

    fun loadCachedRules(): List<FilterRule> {
        val allRules = mutableListOf<FilterRule>()
        val dir = File(context.cacheDir, CACHE_DIR)
        if (!dir.exists()) return allRules
        dir.listFiles()?.forEach { file ->
            try {
                allRules.addAll(parseList(file.readText()))
            } catch (_: Exception) {}
        }
        return allRules
    }

    private fun downloadList(url: String): String {
        val request = Request.Builder().url(url)
            .header("User-Agent", "Webbit/0.1")
            .build()
        val response = client.newCall(request).execute()
        if (!response.isSuccessful) throw RuntimeException("HTTP ${response.code}")
        return response.body!!.string()
    }

    private fun parseList(content: String): List<FilterRule> {
        return content.lines().mapNotNull { FilterParser.parseLine(it) }
    }

    private fun cacheList(name: String, content: String) {
        val dir = File(context.cacheDir, CACHE_DIR)
        dir.mkdirs()
        File(dir, name).writeText(content)
    }

    private fun loadCached(name: String): String? {
        val file = File(File(context.cacheDir, CACHE_DIR), name)
        return if (file.exists()) file.readText() else null
    }
}
