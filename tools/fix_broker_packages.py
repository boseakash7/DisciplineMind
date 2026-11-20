# -*- coding: utf-8 -*-
"""Corrects the 11 broker package ids that do not exist on the Play Store.

Each replacement was verified by fetching the Play Store listing and reading
its og:title - see tools/verify_broker_packages.py.
"""
import pathlib

# old -> (new, play store title it resolves to)
FIXES = {
    "com.icicidirect.mobile": ("com.icicidirect.idirectsuper", "ICICI Direct-Stocks F&O MF IPO"),
    "com.hdfcsec.trade": ("com.hsl.investright", "HDFC Securities InvestRight"),
    "com.sbi.smart": ("com.msf.sbicap.securities", "SBI Securities: Stocks & SIP"),
    "co.dhan": ("com.dhan.live", "Dhan: Stock Market Trading App"),
    "com.motilaloswal.moinvestor": ("com.mosl.mobile", "MO RIISE: Stocks, IPO & Demat"),
    "com.sharekhan": ("com.sharekhan.androidsharemobile", "Mirae Asset Sharekhan: Stocks"),
    "com.axis.direct": ("com.axisdirect.invest", "Axis Direct Investor"),
    "com.choicebroking.jiffy": ("com.choiceequitybroking.jiffy", "FinX - Demat, Stock, FnO & IPO"),
    "com.geojit.selfie": ("com.geojit.flip_mobile", "Geojit Flip-Demat, Stocks, IPO"),
    "com.mshare": ("com.rs.mirae", "mStock: Demat & Stock Trading"),
    "com.sahi.app": ("com.aaritya.sahi_trade_app", "SAHI : Options & Stock Trading"),
}

TARGETS = [
    "lib/ui/widgets/broker_catalog.dart",
    "lib/constants/blocked_apps.dart",
    "android/app/src/main/kotlin/com/example/discipline_mind/AppManager.kt",
    "test/broker_catalog_test.dart",
    "BACKEND_BROKER_APPS_REQUIREMENTS.md",
]

total = 0
for path in TARGETS:
    p = pathlib.Path(path)
    if not p.exists():
        print("skip (missing):", path)
        continue
    s = p.read_text(encoding="utf-8")
    n = 0
    for old, (new, _) in FIXES.items():
        # Word-boundary-ish: these ids only ever appear quoted or in tables.
        before = s
        s = s.replace('"%s"' % old, '"%s"' % new)
        s = s.replace("'%s'" % old, "'%s'" % new)
        s = s.replace("`%s`" % old, "`%s`" % new)
        if s != before:
            n += 1
    if n:
        p.write_text(s, encoding="utf-8")
    print("%-70s %d ids updated" % (path, n))
    total += n

print("\ntotal replacements across files:", total)
