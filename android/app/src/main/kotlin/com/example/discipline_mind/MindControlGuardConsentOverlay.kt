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
        val cb1 = root.findViewById<CheckBox>(R.id.overlay_consent_cb_1)
        val cb2 = root.findViewById<CheckBox>(R.id.overlay_consent_cb_2)
        val cb3 = root.findViewById<CheckBox>(R.id.overlay_consent_cb_3)
        val btnAgree = root.findViewById<TextView>(R.id.overlay_consent_btn_agree)
        val btnCancel = root.findViewById<TextView>(R.id.overlay_consent_btn_cancel)

        var isInternalCheck = false

        fun updateAllState() {
            if (isInternalCheck) return
            val allChecked = cb1.isChecked && cb2.isChecked && cb3.isChecked
            isInternalCheck = true
            cbAll.isChecked = allChecked
            isInternalCheck = false
        }

        cbAll.setOnCheckedChangeListener { _, isChecked ->
            if (isInternalCheck) return@setOnCheckedChangeListener
            isInternalCheck = true
            cb1.isChecked = isChecked
            cb2.isChecked = isChecked
            cb3.isChecked = isChecked
            isInternalCheck = false
        }

        cb1.setOnCheckedChangeListener { _, _ -> updateAllState() }
        cb2.setOnCheckedChangeListener { _, _ -> updateAllState() }
        cb3.setOnCheckedChangeListener { _, _ -> updateAllState() }

        btnAgree.setOnClickListener {
            onAgree()
        }

        btnCancel.setOnClickListener {
            onCancel()
        }

        return root
    }
}
