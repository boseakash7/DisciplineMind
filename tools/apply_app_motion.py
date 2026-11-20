# -*- coding: utf-8 -*-
"""Routes plain `showDialog` call sites through `showAppDialog`.

A plain showDialog fades the barrier but pops the dialog in at full size.
showAppDialog adds the shared fade + scale + rise, and honours the OS
"reduce motion" setting.

Skips the loading spinner in more_screen.dart: that one is shown and
dismissed programmatically within a few hundred ms, so animating it would
make the app feel slower, not smoother.
"""
import pathlib
import re

TARGETS = [
    "lib/ui/credits/widgets/credits_info_dialog.dart",
    "lib/ui/credits/widgets/payment_processing_dialog.dart",
    "lib/ui/credits/widgets/payment_success_dialog.dart",
    "lib/ui/main_home/dmt_score_popup.dart",
    "lib/ui/main_home/mct_analysis_popup.dart",
    "lib/ui/main_home/mct_lessons_screen.dart",
    "lib/ui/main_home/mct_protocols_screen.dart",
    "lib/ui/main_home/trade_process.dart",
    "lib/ui/widgets/common_widgets.dart",
]

IMPORT = "import 'package:discipline_mind/ui/widgets/app_motion.dart';"

changed = 0
for path in TARGETS:
    p = pathlib.Path(path)
    if not p.exists():
        print("skip (missing):", path)
        continue
    s = p.read_text(encoding="utf-8")
    original = s

    # showDialog<T>( / showDialog( -> showAppDialog<T>( / showAppDialog<void>(
    s = re.sub(r"\bshowDialog<", "showAppDialog<", s)
    s = re.sub(r"\bshowDialog\(", "showAppDialog<void>(", s)

    if s == original:
        print("%-62s no change" % path)
        continue

    if IMPORT not in s:
        # Insert after the first import so ordering stays tidy.
        first = s.index("import ")
        end = s.index("\n", first) + 1
        s = s[:end] + IMPORT + "\n" + s[end:]

    p.write_text(s, encoding="utf-8")
    print("%-62s updated" % path)
    changed += 1

print("\nfiles updated:", changed)
