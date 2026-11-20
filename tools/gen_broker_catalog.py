# -*- coding: utf-8 -*-
"""One-shot generator: extracts the broker logo builders out of
trade_process.dart into the shared lib/ui/widgets/broker_catalog.dart.

Kept in tools/ so the extraction is reproducible and reviewable.
"""
import pathlib

SRC = pathlib.Path('lib/ui/main_home/trade_process.dart')
OUT = pathlib.Path('lib/ui/widgets/broker_catalog.dart')

src = SRC.read_text(encoding='utf-8').split('\n')

ls = next(i for i, l in enumerate(src) if l.startswith('  static Widget _buildGrowwLogo('))
le = next(i for i, l in enumerate(src) if l.startswith('  String _getBrokerPackageName('))
logos_block = '\n'.join(src[ls:le]).rstrip()

ds = next(i for i, l in enumerate(src) if l.startswith('  static Widget _defaultBrokerLogo('))
de = next(i for i in range(ds + 1, len(src)) if src[i] == '  }')
default_block = '\n'.join(src[ds:de + 1])


def dedent(block):
    out = []
    for l in block.split('\n'):
        if l.startswith('  static Widget '):
            l = l.replace('  static Widget ', 'Widget ', 1)
        elif l.startswith('  '):
            l = l[2:]
        out.append(l)
    return '\n'.join(out)


logos = dedent(logos_block).replace('.withOpacity(', '.withValues(alpha: ')
default = dedent(default_block).replace('.withOpacity(', '.withValues(alpha: ')

ENTRIES = [
    ("Groww", "com.nextbillion.groww", "assets/groww.png", "0xFF00D09C", "_buildGrowwLogo"),
    ("Zerodha", "com.zerodha.kite3", "assets/ZerodhaKite.png", "0xFF387ED1", "_buildZerodhaLogo"),
    ("Angel One", "com.msf.angelmobile", "", "0xFFEB5B28", "_buildAngelOneLogo"),
    ("ICICI Direct", "com.icicidirect.mobile", "", "0xFFB01D22", "_buildIciciLogo"),
    ("Upstox", "in.upstox.app", "assets/upsocks.png", "0xFF702FB2", "_buildUpstoxLogo"),
    ("Kotak Neo", "com.kotak.neo", "", "0xFFE31B23", "_buildKotakLogo"),
    ("HDFC Securities", "com.hdfcsec.trade", "", "0xFF004C8F", "_buildHdfcLogo"),
    ("SBI Securities", "com.sbi.smart", "", "0xFF0081C6", "_buildSbiLogo"),
    ("Dhan", "co.dhan", "", "0xFF00A669", "_buildDhanLogo"),
    ("Motilal Oswal", "com.motilaloswal.moinvestor", "", "0xFFF39200", "_buildMotilalLogo"),
    ("Paytm Money", "com.paytmmoney", "", "0xFF002E6C", "_buildPaytmLogo"),
    ("INDmoney", "in.indwealth", "", "0xFF000000", "_buildIndMoneyLogo"),
    ("Sharekhan", "com.sharekhan", "", "0xFFF26522", "_buildSharekhanLogo"),
    ("Axis Securities", "com.axis.direct", "", "0xFF97123A", "_buildAxisLogo"),
    ("IIFL Securities", "com.indiainfoline", "", "0xFFF37023", "_buildIiflLogo"),
    ("5paisa", "com.fivepaisa.trade", "", "0xFFCF1222", "_buildFivePaisaLogo"),
    ("Choice", "com.choicebroking.jiffy", "", "0xFF0068B3", "_buildChoiceLogo"),
    ("Geojit", "com.geojit.selfie", "", "0xFF008269", "_buildGeojitLogo"),
    ("Mirae Asset", "com.mshare", "", "0xFF00457C", "_buildMiraeLogo"),
    ("Sahi", "com.sahi.app", "", "0xFF0E1E38", "_buildSahiLogo"),
]

rows = []
for name, pkg, asset, color, fn in ENTRIES:
    asset_line = "    assetPath: '%s',\n" % asset if asset else ""
    rows.append(
        "  BrokerItem(\n"
        "    name: '%s',\n"
        "    packageName: '%s',\n"
        "%s"
        "    brandColor: Color(%s),\n"
        "    logoBuilder: %s,\n"
        "  )," % (name, pkg, asset_line, color, fn)
    )
catalog = '\n'.join(rows)

TEMPLATE = pathlib.Path('tools/broker_catalog_template.dart.txt').read_text(encoding='utf-8')
OUT.write_text(
    TEMPLATE.replace('/*CATALOG*/', catalog)
            .replace('/*DEFAULT_LOGO*/', default)
            .replace('/*LOGOS*/', logos),
    encoding='utf-8',
)
print('wrote', OUT)
