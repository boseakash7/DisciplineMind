package com.discipline.mind

/** Centralized API configuration for native Android code. */
internal object NativeApiConfig {
     const val BASE_URL = "https://api.disciplinedminds.in/api/" // LIVE
    //const val BASE_URL = "https://staging-api.disciplinedminds.in/api/" // STAGING

    const val V2_TEST_BASE_URL = "${BASE_URL}v2test/"
    const val PHASE5_BASE_URL = BASE_URL

    const val APP_STATE_PATH = "app/state"
    const val APP_FORCE_UNLOCK_PATH = "app/force-unlock"
    const val USAGE_TRACKING_FALLBACK_URL = "https://httpbin.org/post"

    fun v2TestUrl(path: String): String = buildUrl(V2_TEST_BASE_URL, path)

    private fun buildUrl(baseUrl: String, path: String): String =
        "${baseUrl.trimEnd('/')}/${path.trimStart('/')}"
}
