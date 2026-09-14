package com.discipline.mind

import android.content.Context
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.widget.CheckBox
import android.widget.TextView

/**
 * Native Mind Control Guard Consent & Acknowledgement overlay.
 * Shown on first-time opening of a blocked trading app before revealing the lock screen.
 */
object MindControlGuardConsentOverlay {

    fun create(
        context: Context,
        onAgree: () -> Unit,
        onCancel: () -> Unit,
    ): View {
        val root = LayoutInflater.from(context).inflate(
            R.layout.overlay_mind_control_guard_consent,
            null,
            false,
        )

        val statusBarId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        val navId = context.resources.getIdentifier("navigation_bar_height", "dimen", "android")
        val extraTop = if (statusBarId > 0) {
            context.resources.getDimensionPixelSize(statusBarId)
        } else {
            TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                28f,
                context.resources.displayMetrics,
            ).toInt()
        }
        val extraBottom = if (navId > 0) {
            context.resources.getDimensionPixelSize(navId)
        } else {
            0
        }
        root.setPadding(
            root.paddingLeft,
            root.paddingTop + extraTop,
            root.paddingRight,
            root.paddingBottom + extraBottom,
        )

        val cbAll = root.findViewById<CheckBox>(R.id.overlay_consent_cb_all)
        val btnAgree = root.findViewById<TextView>(R.id.overlay_consent_btn_agree)
        val btnCancel = root.findViewById<TextView>(R.id.overlay_consent_btn_cancel)

        btnAgree.setOnClickListener {
            cbAll.isChecked = true
            onAgree()
        }

        btnCancel.setOnClickListener {
            onCancel()
        }

        return root
    }
}
