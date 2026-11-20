# -*- coding: utf-8 -*-
"""Checks every broker package id in the catalogue against the Play Store.

Run:  python -I tools/verify_broker_packages.py
Needs only the stdlib. Prints OK / MISSING per package, and for missing ones
suggests candidates found via Play Store search with their listed titles.
"""
import html
import re
import sys
import urllib.parse
import pathlib
import urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " \
     "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return r.getcode(), r.read().decode("utf-8", "ignore")
    except urllib.error.HTTPError as e:
        return e.code, ""
    except Exception:
        return 0, ""


def title_for(pkg):
    code, body = _get(
        "https://play.google.com/store/apps/details?id=%s&gl=IN&hl=en" % pkg
    )
    if code != 200:
        return code, None
    m = re.search(r"<title>(.*?)</title>", body, re.S)
    t = html.unescape(m.group(1)).strip() if m else ""
    t = t.replace(" - Apps on Google Play", "")
    return code, t


def search(query, limit=6):
    q = urllib.parse.quote(query)
    code, body = _get(
        "https://play.google.com/store/search?q=%s&c=apps&gl=IN&hl=en" % q
    )
    if code != 200:
        return []
    ids, seen = [], set()
    for m in re.finditer(r"id=([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)", body):
        pkg = m.group(1)
        if pkg in seen:
            continue
        seen.add(pkg)
        ids.append(pkg)
        if len(ids) >= limit:
            break
    return ids


def load_catalogue():
    """Reads name/packageName straight out of broker_catalog.dart so this
    checker can never drift from the app."""
    src = pathlib.Path("lib/ui/widgets/broker_catalog.dart").read_text(
        encoding="utf-8"
    )
    block = src[src.index("kBrokerCatalog"):]
    out = []
    pattern = (
        r"name:\s*'([^']+)',\s*"
        r"brokingAppKey:\s*'[^']*',\s*"
        r"packageName:\s*'([^']+)'"
    )
    for m in re.finditer(pattern, block):
        out.append((m.group(1), m.group(2), m.group(1) + " trading app India"))
    return out


BROKERS = load_catalogue()


def main():
    bad = []
    for name, pkg, query in BROKERS:
        code, title = title_for(pkg)
        if code == 200:
            print("OK       %-28s %-30s %s" % (name, pkg, title or ""))
        else:
            print("MISSING  %-28s %-30s HTTP %s" % (name, pkg, code))
            bad.append((name, pkg, query))

    if not bad:
        print("\nAll package ids resolve on the Play Store.")
        return 0

    print("\n--- candidates for the missing ones ---")
    for name, pkg, query in bad:
        print("\n%s  (current: %s)" % (name, pkg))
        for cand in search(query):
            ccode, ctitle = title_for(cand)
            if ccode == 200:
                print("    %-34s %s" % (cand, ctitle or ""))
    return 1


if __name__ == "__main__":
    sys.exit(main())
