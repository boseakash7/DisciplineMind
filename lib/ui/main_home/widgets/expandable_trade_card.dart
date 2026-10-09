import 'package:flutter/material.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';

class ExpandableTradeCard extends StatefulWidget {
  final String title;
  final String date;
  final bool profit;
  final String returnLabel;
  final DmtHitTrade? trade;
  final Color cardColor;

  const ExpandableTradeCard({
    super.key,
    required this.title,
    required this.date,
    required this.profit,
    required this.returnLabel,
    required this.cardColor,
    this.trade,
  });

  @override
  State<ExpandableTradeCard> createState() => _ExpandableTradeCardState();
}

class _ExpandableTradeCardState extends State<ExpandableTradeCard> {
  bool expanded = false;

  void toggle() {
    setState(() {
      expanded = !expanded;
    });
  }

  String fmt(double? v) {
    if (v == null) return '';
    return v.toStringAsFixed(2);
  }

  Color _returnValueColor(double? value, {bool? positiveFallback}) {
    if (value != null) {
      return value >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }
    if (positiveFallback != null) {
      return positiveFallback
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);
    }
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF64748B);
  }

  Widget _returnValue(
    String label,
    String value,
    double? rawValue, {
    bool? positiveFallback,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF161338),
          fontSize: 12,
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: _returnValueColor(
                rawValue,
                positiveFallback: positiveFallback,
              ),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsRow() {
    final trade = widget.trade;
    final myValue = trade?.returnPercent;
    final mctValue = trade?.mctReturnPercentage;
    final myLabel = trade?.displayReturn ?? widget.returnLabel;
    final mctLabel = trade?.displayMctReturn ?? '-';

    final returnWidgets = <Widget>[];
    if (myLabel.trim().isNotEmpty &&
        myLabel.trim() != '-' &&
        myLabel.trim() != '—') {
      returnWidgets.add(
        _returnValue(
          'My Return',
          myLabel,
          myValue,
          positiveFallback: myValue == null ? widget.profit : null,
        ),
      );
    }
    if (mctLabel.trim().isNotEmpty &&
        mctLabel.trim() != '-' &&
        mctLabel.trim() != '—') {
      returnWidgets.add(_returnValue('MCT Return', mctLabel, mctValue));
    }
    if (returnWidgets.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 14, runSpacing: 2, children: returnWidgets);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? const Color(0xFF1E1B2E) : Colors.white;
    final innerBg = dark ? const Color(0xFF272338) : const Color(0xFFF8F7FD);
    final borderColor = dark
        ? const Color(0xFF332F49)
        : const Color(0xFFF1EEFA);
    final titleColor = dark ? Colors.white : const Color(0xFF161338);
    final subColor = dark ? Colors.white70 : const Color(0xFF64748B);
    final profitColor = widget.profit
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    final initial = widget.title.isNotEmpty
        ? widget.title.substring(0, 1).toUpperCase()
        : 'T';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          if (!dark)
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF2D2644)
                          : const Color(0xFFF3EEFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Date - ${formatTradeTabDate(widget.date)}',
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildReturnsRow(),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Return',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.returnLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6D28D9),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: widget.trade == null
                  ? Column(
                      children: [
                        _buildRow(
                          'Date',
                          formatTradeTabDate(widget.date),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Return',
                          widget.returnLabel,
                          subColor,
                          profitColor,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildRow(
                          'Trade Name',
                          widget.trade?.displayExpandedTradeName ?? '',
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Trade Hit at',
                          widget.trade?.displayHitAt ?? '',
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Entry Price',
                          fmt(
                            widget.trade?.trade?.entryPrice ??
                                widget.trade?.gttPrice,
                          ),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'SL placed at',
                          fmt(
                            widget.trade?.trade?.stopLoss ??
                                widget.trade?.lowerPrice,
                          ),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Exit Price',
                          fmt(
                            widget.trade?.trade?.takeProfit ??
                                widget.trade?.upperPrice,
                          ),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Hit Price',
                          fmt(widget.trade?.displayHitPrice),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Target',
                          fmt(widget.trade?.upperPrice),
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'Created',
                          widget.trade?.displayCreatedAt ?? '',
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'My Exit',
                          widget.trade?.displayMyExitDetail ?? '',
                          subColor,
                          titleColor,
                        ),
                        _buildRow(
                          'MCT Exit',
                          widget.trade?.displayMctExitDetail ?? '',
                          subColor,
                          titleColor,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
