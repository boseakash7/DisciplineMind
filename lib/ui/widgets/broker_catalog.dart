/// Single source of truth for the broker apps the user can pick.
///
/// Both the setup flow and the app-block settings screen render this list
/// through [BrokerGrid], so the two pickers cannot drift apart.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color _purple = Color(0xFF4A22F4);
const Color _ink = Color(0xFF10122D);
const Color _unselectedBorder = Color(0xFFE2E0E9);

/// One broker the user can select.
class BrokerItem {
  const BrokerItem({
    required this.name,
    required this.packageName,
    required this.brokingAppKey,
    this.assetPath,
    this.brandColor = _purple,
    this.logoBuilder,
  });

  final String name;

  /// Android package id. Used for blocking and for matching API rows.
  final String packageName;

  /// Value sent as `broking_app` to `process/setup` and `process/edit`.
  final String brokingAppKey;
  final String? assetPath;
  final Color brandColor;
  final Widget Function()? logoBuilder;
}

/// The brokers bundled with the app. Package names must stay in step with
/// `lib/constants/blocked_apps.dart` and with `GET /api/trading-apps`.
const List<BrokerItem> kBrokerCatalog = <BrokerItem>[
  BrokerItem(
    name: 'Groww',
    brokingAppKey: 'groww',
    packageName: 'com.nextbillion.groww',
    assetPath: 'assets/groww.png',
    brandColor: Color(0xFF00D09C),
    logoBuilder: _buildGrowwLogo,
  ),
  BrokerItem(
    name: 'Zerodha',
    brokingAppKey: 'zerodha',
    packageName: 'com.zerodha.kite3',
    assetPath: 'assets/ZerodhaKite.png',
    brandColor: Color(0xFF387ED1),
    logoBuilder: _buildZerodhaLogo,
  ),
  BrokerItem(
    name: 'Angel One',
    brokingAppKey: 'angel_one',
    packageName: 'com.msf.angelmobile',
    brandColor: Color(0xFFEB5B28),
    logoBuilder: _buildAngelOneLogo,
  ),
  BrokerItem(
    name: 'ICICI Direct',
    brokingAppKey: 'icici_direct',
    packageName: 'com.icicidirect.idirectsuper',
    brandColor: Color(0xFFB01D22),
    logoBuilder: _buildIciciLogo,
  ),
  BrokerItem(
    name: 'Upstox',
    brokingAppKey: 'upstox',
    packageName: 'in.upstox.app',
    assetPath: 'assets/upsocks.png',
    brandColor: Color(0xFF702FB2),
    logoBuilder: _buildUpstoxLogo,
  ),
  BrokerItem(
    name: 'Kotak Neo',
    brokingAppKey: 'kotak_neo',
    packageName: 'com.kotak.neo',
    brandColor: Color(0xFFE31B23),
    logoBuilder: _buildKotakLogo,
  ),
  BrokerItem(
    name: 'HDFC Securities',
    brokingAppKey: 'hdfc_securities',
    packageName: 'com.hsl.investright',
    brandColor: Color(0xFF004C8F),
    logoBuilder: _buildHdfcLogo,
  ),
  BrokerItem(
    name: 'SBI Securities',
    brokingAppKey: 'sbi_securities',
    packageName: 'com.msf.sbicap.securities',
    brandColor: Color(0xFF0081C6),
    logoBuilder: _buildSbiLogo,
  ),
  BrokerItem(
    name: 'Dhan',
    brokingAppKey: 'dhan',
    packageName: 'com.dhan.live',
    brandColor: Color(0xFF00A669),
    logoBuilder: _buildDhanLogo,
  ),
  BrokerItem(
    name: 'Motilal Oswal',
    brokingAppKey: 'motilal_oswal',
    packageName: 'com.mosl.mobile',
    brandColor: Color(0xFFF39200),
    logoBuilder: _buildMotilalLogo,
  ),
  BrokerItem(
    name: 'Paytm Money',
    brokingAppKey: 'paytm_money',
    packageName: 'com.paytmmoney',
    brandColor: Color(0xFF002E6C),
    logoBuilder: _buildPaytmLogo,
  ),
  BrokerItem(
    name: 'INDmoney',
    brokingAppKey: 'indmoney',
    packageName: 'in.indwealth',
    brandColor: Color(0xFF000000),
    logoBuilder: _buildIndMoneyLogo,
  ),
  BrokerItem(
    name: 'Sharekhan',
    brokingAppKey: 'sharekhan',
    packageName: 'com.sharekhan.androidsharemobile',
    brandColor: Color(0xFFF26522),
    logoBuilder: _buildSharekhanLogo,
  ),
  BrokerItem(
    name: 'Axis Securities',
    brokingAppKey: 'axis_securities',
    packageName: 'com.axisdirect.invest',
    brandColor: Color(0xFF97123A),
    logoBuilder: _buildAxisLogo,
  ),
  BrokerItem(
    name: 'IIFL Securities',
    brokingAppKey: 'iifl_securities',
    packageName: 'com.indiainfoline',
    brandColor: Color(0xFFF37023),
    logoBuilder: _buildIiflLogo,
  ),
  BrokerItem(
    name: '5paisa',
    brokingAppKey: '5paisa',
    packageName: 'com.fivepaisa.trade',
    brandColor: Color(0xFFCF1222),
    logoBuilder: _buildFivePaisaLogo,
  ),
  BrokerItem(
    name: 'Choice',
    brokingAppKey: 'choice',
    packageName: 'com.choiceequitybroking.jiffy',
    brandColor: Color(0xFF0068B3),
    logoBuilder: _buildChoiceLogo,
  ),
  BrokerItem(
    name: 'Geojit',
    brokingAppKey: 'geojit',
    packageName: 'com.geojit.flip_mobile',
    brandColor: Color(0xFF008269),
    logoBuilder: _buildGeojitLogo,
  ),
  BrokerItem(
    name: 'Mirae Asset',
    brokingAppKey: 'mirae_asset',
    packageName: 'com.rs.mirae',
    brandColor: Color(0xFF00457C),
    logoBuilder: _buildMiraeLogo,
  ),
  BrokerItem(
    name: 'Sahi',
    brokingAppKey: 'sahi',
    packageName: 'com.aaritya.sahi_trade_app',
    brandColor: Color(0xFF0E1E38),
    logoBuilder: _buildSahiLogo,
  ),
];

/// Collapses broker names to a stable key, so "Zerodha Kite" and "Zerodha"
/// resolve to the same broker.
String normalizeBrokerName(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.contains('zerodha') || lower.contains('kite')) return 'zerodha';
  if (lower.contains('upstox')) return 'upstox';
  if (lower.contains('groww')) return 'groww';
  if (lower.contains('angel')) return 'angel_one';
  if (lower.contains('dhan')) return 'dhan';
  if (lower.contains('icici')) return 'icici_direct';
  if (lower.contains('kotak')) return 'kotak_neo';
  if (lower.contains('hdfc')) return 'hdfc_securities';
  if (lower.contains('sbi')) return 'sbi_securities';
  if (lower.contains('motilal')) return 'motilal_oswal';
  if (lower.contains('paytm')) return 'paytm_money';
  if (lower.contains('ind')) return 'ind_money';
  if (lower.contains('sharekhan')) return 'sharekhan';
  if (lower.contains('axis')) return 'axis_securities';
  if (lower.contains('iifl')) return 'iifl_securities';
  if (lower.contains('5paisa')) return '5paisa';
  if (lower.contains('choice')) return 'choice';
  if (lower.contains('geojit')) return 'geojit';
  if (lower.contains('mirae')) return 'mirae_asset';
  if (lower.contains('sahi')) return 'sahi';
  return lower;
}

bool isSameBroker(String? a, String? b) {
  if (a == null || b == null) return false;
  return normalizeBrokerName(a) == normalizeBrokerName(b);
}

/// Package id for a display name, or an empty string when unknown.
String brokerPackageForName(String? name) {
  if (name == null || name.trim().isEmpty) return '';
  final key = normalizeBrokerName(name);
  for (final item in kBrokerCatalog) {
    if (normalizeBrokerName(item.name) == key) return item.packageName;
  }
  return '';
}

/// `broking_app` key for a display name, falling back to a slug.
String brokingAppKeyForName(String? name) {
  if (name == null || name.trim().isEmpty) return '';
  final key = normalizeBrokerName(name);
  for (final item in kBrokerCatalog) {
    if (normalizeBrokerName(item.name) == key) return item.brokingAppKey;
  }
  return key;
}

/// Catalogue entry matching a stored `broking_app` key or display name.
BrokerItem? brokerForBrokingAppKey(String? key) {
  if (key == null || key.trim().isEmpty) return null;
  final lower = key.trim().toLowerCase();
  for (final item in kBrokerCatalog) {
    if (item.brokingAppKey == lower) return item;
  }
  final normalized = normalizeBrokerName(lower);
  for (final item in kBrokerCatalog) {
    if (normalizeBrokerName(item.name) == normalized) return item;
  }
  return null;
}

/// Catalogue entry for a package id, when the app knows that broker.
BrokerItem? brokerForPackage(String packageName) {
  for (final item in kBrokerCatalog) {
    if (item.packageName == packageName) return item;
  }
  return null;
}

/// The bundled catalogue plus any broker the backend returned that is not
/// bundled yet, so new brokers appear without an app release.
List<BrokerItem> effectiveBrokerList(
  Iterable<({String name, String packageName})> apiApps,
) {
  final list = List<BrokerItem>.from(kBrokerCatalog);
  for (final app in apiApps) {
    if (app.name.trim().isEmpty) continue;
    final exists = list.any(
      (item) =>
          item.packageName == app.packageName ||
          isSameBroker(item.name, app.name),
    );
    if (!exists) {
      list.add(
        BrokerItem(
          name: app.name,
          packageName: app.packageName,
          brokingAppKey: normalizeBrokerName(app.name),
        ),
      );
    }
  }
  return list;
}

/// Logo for a broker: bundled asset, then hand-built logo, then an initial.
Widget brokerLogoWidget(BrokerItem item) {
  final asset = item.assetPath;
  if (asset != null && asset.isNotEmpty) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          item.logoBuilder?.call() ??
          defaultBrokerLogo(item.name, item.brandColor),
    );
  }
  if (item.logoBuilder != null) return item.logoBuilder!();
  return defaultBrokerLogo(item.name, item.brandColor);
}

/// Four-across broker picker, shared by setup and settings.
class BrokerGrid extends StatelessWidget {
  const BrokerGrid({
    super.key,
    required this.brokers,
    required this.selectedPackageName,
    required this.onSelected,
    this.columns = 4,
  });

  final List<BrokerItem> brokers;
  final String? selectedPackageName;
  final ValueChanged<BrokerItem> onSelected;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < brokers.length; i += columns) {
      final end = (i + columns) > brokers.length ? brokers.length : i + columns;
      final chunk = brokers.sublist(i, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(
                child: j < chunk.length
                    ? BrokerGridTile(
                        item: chunk[j],
                        selected: chunk[j].packageName == selectedPackageName,
                        onTap: () => onSelected(chunk[j]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (end < brokers.length) rows.add(const SizedBox(height: 10));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// One tile in [BrokerGrid].
class BrokerGridTile extends StatelessWidget {
  const BrokerGridTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BrokerItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFAF7FE) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _purple : _unselectedBorder,
              width: selected ? 1.8 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _purple.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 40, height: 40, child: brokerLogoWidget(item)),
              const SizedBox(height: 6),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? _purple : _ink,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget defaultBrokerLogo(String name, Color color) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : 'B';
  return Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text(
      letter,
      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
    ),
  );
}

Widget _buildGrowwLogo() {
  return Container(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFF00D09C), Color(0xFF00B587)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
  );
}

Widget _buildZerodhaLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF387ED1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    ),
  );
}

Widget _buildAngelOneLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2EC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFFE0D2)),
    ),
    child: const Center(
      child: Icon(
        Icons.change_history_rounded,
        color: Color(0xFFEB5B28),
        size: 24,
      ),
    ),
  );
}

Widget _buildIciciLogo() {
  return Container(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFFB01D22), Color(0xFFE35300)]),
    ),
    child: const Center(
      child: Text(
        'i',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
}

Widget _buildUpstoxLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF702FB2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        'up',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    ),
  );
}

Widget _buildKotakLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE31B23),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 16),
          Text(
            'neo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 0.9,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHdfcLogo() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE31B23), width: 2),
    ),
    child: Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF004C8F),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

Widget _buildSbiLogo() {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFF0081C6),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0081C6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildDhanLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF00A669),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        'ध',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

Widget _buildMotilalLogo() {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF39200),
      shape: BoxShape.circle,
    ),
    child: const Center(
      child: Text(
        'M',
        style: TextStyle(
          color: Color(0xFF10122D),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildPaytmLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF002E6C),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        '₹',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

Widget _buildIndMoneyLogo() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E0E9)),
    ),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 14),
          Text(
            'IND',
            style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 0.9,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSharekhanLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0E6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFFD4BD)),
    ),
    child: const Center(
      child: Icon(Icons.pets_rounded, color: Color(0xFFF26522), size: 22),
    ),
  );
}

Widget _buildAxisLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF97123A),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildIiflLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF37023),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
    ),
  );
}

Widget _buildFivePaisaLogo() {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFCF1222), Color(0xFF9A0B17)],
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        '5',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildChoiceLogo() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF0068B3), width: 2),
    ),
    child: const Center(
      child: Text(
        'C',
        style: TextStyle(
          color: Color(0xFF0068B3),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildGeojitLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF008269),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildMiraeLogo() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E0E9)),
    ),
    child: const Center(
      child: Icon(Icons.show_chart_rounded, color: Color(0xFF00457C), size: 22),
    ),
  );
}

Widget _buildSahiLogo() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0E1E38),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        'S',
        style: TextStyle(
          color: Color(0xFF00E676),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
