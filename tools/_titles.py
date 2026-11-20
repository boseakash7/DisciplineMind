# -*- coding: utf-8 -*-
import html, re, urllib.request, urllib.error
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
CANDS = [
 ("ICICI Direct", "com.icicidirect.idirectsuper"),
 ("HDFC Securities", "com.cloudtradetech.sky"),
 ("HDFC Securities", "com.hsl.investright"),
 ("SBI Securities", "com.msf.sbicap.securities"),
 ("Dhan", "com.dhan.live"),
 ("Motilal Oswal", "com.mosl.mobile"),
 ("Sharekhan", "com.sharekhan.androidsharemobile"),
 ("Axis Securities", "com.axisdirect.invest"),
 ("Axis Securities", "com.axisdirect.orbit"),
 ("Choice", "com.choiceequitybroking.jiffy"),
 ("Geojit", "com.geojit.flip_mobile"),
 ("Mirae Asset", "com.rs.mirae"),
 ("Mirae Asset", "com.mirae.investor.app"),
 ("Sahi", "com.aaritya.sahi_trade_app"),
]
for name, pkg in CANDS:
    req = urllib.request.Request(
        "https://play.google.com/store/apps/details?id=%s&gl=IN&hl=en" % pkg,
        headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            body = r.read().decode("utf-8", "ignore")
        m = re.search(r'<meta name="appstore:developer_url"', body)
        t = re.search(r'<meta property="og:title" content="([^"]+)"', body)
        d = re.search(r'<meta property="og:description" content="([^"]{0,70})', body)
        title = html.unescape(t.group(1)) if t else "?"
        desc = html.unescape(d.group(1)) if d else ""
        print("%-18s %-34s %-42s %s" % (name, pkg, title, desc))
    except urllib.error.HTTPError as e:
        print("%-18s %-34s HTTP %s" % (name, pkg, e.code))
    except Exception as e:
        print("%-18s %-34s ERR %s" % (name, pkg, e))
