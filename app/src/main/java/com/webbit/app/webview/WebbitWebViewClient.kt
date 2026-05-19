package com.webbit.app.webview

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import com.webbit.app.adblock.AdBlockerEngine

class WebbitWebViewClient(
    private val adBlocker: AdBlockerEngine,
) : WebViewClient() {

    private val extensionResourceTypes = mapOf(
        "js" to "script",
        "css" to "stylesheet",
        "png" to "image",
        "jpg" to "image",
        "jpeg" to "image",
        "gif" to "image",
        "svg" to "image",
        "webp" to "image",
        "ico" to "image",
        "woff" to "font",
        "woff2" to "font",
        "ttf" to "font",
        "otf" to "font",
        "eot" to "font",
        "mp4" to "media",
        "webm" to "media",
        "ogg" to "media",
        "mp3" to "media",
    )

    override fun shouldInterceptRequest(
        view: WebView,
        request: WebResourceRequest,
    ): WebResourceResponse? {
        if (request.isForMainFrame) return null

        val url = request.url.toString()
        val resourceType = inferResourceType(request)

        if (adBlocker.shouldBlock(url, resourceType)) {
            return blockedResponse()
        }

        return super.shouldInterceptRequest(view, request)
    }

    private fun inferResourceType(request: WebResourceRequest): String? {
        val path = request.url.path ?: return null
        val ext = path.substringAfterLast('.', "").lowercase()
        return extensionResourceTypes[ext]
    }

    private fun blockedResponse() = WebResourceResponse("text/plain", "utf-8", null)
}
