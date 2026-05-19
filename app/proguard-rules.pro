# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public boolean shouldOverrideUrlLoading(android.webkit.WebView, java.lang.String);
    public android.webkit.WebResourceResponse shouldInterceptRequest(android.webkit.WebView, android.webkit.WebResourceRequest);
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
