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
    if (v == null) return '-';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? const Color(0xFF1E1B2E) : Colors.white;
    final innerBg = dark ? const Color(0xFF272338) : const Color(0xFFF8F7FD);
    final borderColor = dark ? const Color(0xFF332F49) : const Color(0xFFF1EEFA);
    final titleColor = dark ? Colors.white : const Color(0xFF161338);
    final subColor = dark ? Colors.white70 : const Color(0xFF64748B);
    final profitColor = widget.profit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final initial = widget.title.isNotEmpty ? widget.title.substring(0, 1).toUpperCase() : 'T';

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
                      color: dark ? const Color(0xFF2D2644) : const Color(0xFFF3EEFF),
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
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                        _buildRow('Date', formatTradeTabDate(widget.date), subColor, titleColor),
                        _buildRow('Return', widget.returnLabel, subColor, profitColor),
                      ],
                    )
                  : Column(
                      children: [
                        _buildRow('Hit Price', fmt(widget.trade?.hitPrice), subColor, titleColor),
                        _buildRow('Target', fmt(widget.trade?.upperPrice), subColor, titleColor),
                        _buildRow('Stop Loss', fmt(widget.trade?.lowerPrice), subColor, titleColor),
                        _buildRow(
                          'Created',
                          widget.trade?.displayCreatedAt ?? '',
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

  Widget _buildRow(String label, String value, Color labelColor, Color valueColor) {
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