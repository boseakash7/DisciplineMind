package com.discipline.mind

/** Centralized API configuration for native Android code. */
internal object NativeApiConfig {
    // Previous production URLs (kept commented for reference):
    // const val LEGACY_V2_TEST_BASE_URL = "https://api.disciplinedminds.in/api/v2test/"
    // const val LEGACY_PHASE5_BASE_URL = "https://api.disciplinedminds.in/api/"

    const val V2_TEST_BASE_URL = "https://staging-api.disciplinedminds.in/api/v2test/"
    const val PHASE5_BASE_URL = "https://staging-api.disciplinedminds.in/api/"

    const val APP_STATE_PATH = "app/state"
    const val APP_FORCE_UNLOCK_PATH = "app/force-unlock"
    const val USAGE_TRACKING_FALLBACK_URL = "https://httpbin.org/post"

    fun v2TestUrl(path: String): String = buildUrl(V2_TEST_BASE_URL, path)

    private fun buildUrl(baseUrl: String, path: String): String =
        "${baseUrl.trimEnd('/')}/${path.trimStart('/')}"
}
