package com.discipline.mind

import android.content.Context
import android.graphics.Typeface
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat

/**
 * Native Mind Control Guard lock overlay shown when a blocked trading app is opened.
 */
object MindControlGuardOverlay {

    fun create(
        context: Context,
        hasActiveTrade: Boolean,
        onWillControl: () -> Unit,
        onSkip: () -> Unit,
    ): View {
        val root = LayoutInflater.from(context).inflate(
            R.layout.overlay_mind_control_guard,
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

        root.findViewById<View>(R.id.overlay_btn_control).setOnClickListener { onWillControl() }
        root.findViewById<View>(R.id.overlay_btn_skip).setOnClickListener { onSkip() }
        bindStatus(root, hasActiveTrade)
        return root
    }

    fun bindStatus(root: View, hasActiveTrade: Boolean) {
        val icon = root.findViewById<ImageView>(R.id.overlay_status_icon) ?: return
        val title = root.findViewById<TextView>(R.id.overlay_status_title) ?: return
        val subtitle = root.findViewById<TextView>(R.id.overlay_status_subtitle) ?: return
        val cardTitle = root.findViewById<TextView>(R.id.overlay_card_title) ?: return
        val cardBody = root.findViewById<TextView>(R.id.overlay_card_body) ?: return

        if (hasActiveTrade) {
            icon.setImageResource(R.drawable.ic_overlay_bolt)
            title.text = "Trade is active"
            subtitle.text = "from the Analyst — stick to the plan"
            cardTitle.text = highlightPhrase(
                root.context,
                "Protect the\nlive trade.",
                "live trade",
            )
            cardBody.text = highlightPhrase(
                root.context,
                "Stay with the Analyst's plan,\nnot the next candle.",
                "Analyst's plan",
            )
        } else {
            icon.setImageResource(R.drawable.ic_overlay_hourglass)
            title.text = "No new signal yet"
            subtitle.text = "from the Analyst"
            cardTitle.text = highlightPhrase(
                root.context,
                "Save yourself\nfrom FOMO.",
                "FOMO",
            )
            cardBody.text = highlightPhrase(
                root.context,
                "Mind control traders\nwait for right signal, not the noise.",
                "right signal",
            )
        }
    }

    private fun highlightPhrase(context: Context, full: String, phrase: String): CharSequence {
        val span = SpannableString(full)
        val start = full.indexOf(phrase, ignoreCase = true)
        if (start >= 0) {
            val end = start + phrase.length
            val color = ContextCompat.getColor(context, R.color.overlay_purple_deep)
            span.setSpan(ForegroundColorSpan(color), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            span.setSpan(StyleSpan(Typeface.BOLD), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        return span
    }
}
