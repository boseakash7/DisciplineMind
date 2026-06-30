import 'package:flutter/material.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';

class ExpandableTradeCard extends StatefulWidget {
  final String title;
  final String date;
  final bool profit;
  final String returnLabel;
  final DmtHitTrade? trade;

  /// Pass selected level color
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
  State<ExpandableTradeCard> createState() =>
      _ExpandableTradeCardState();
}

class _ExpandableTradeCardState
    extends State<ExpandableTradeCard> {
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
    final dark =
        Theme.of(context).brightness ==
        Brightness.dark;

    final bg =
        widget.cardColor;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      decoration:
          BoxDecoration(
        color: bg,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 10,

            color: bg.withOpacity(
              .25,
            ),
          ),
        ],
      ),

      child: Column(
        children: [
          InkWell(
            borderRadius:
                BorderRadius.circular(
              14,
            ),

            onTap: toggle,

            child: Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,

                    backgroundColor:
                        dark
                            ? Colors
                                .white24
                            : Colors
                                .white,

                    child: Text(
                      widget.title
                          .substring(
                        0,
                        1,
                      ),

                      style:
                          TextStyle(
                        color:
                            widget
                                .cardColor,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          widget.title,

                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white,

                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Date - ${formatTradeTabDate(widget.date)}',

                          style:
                              TextStyle(
                            color:
                                Colors
                                    .white
                                    .withOpacity(
                                      .8,
                                    ),

                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,

                    children: [
                      const Text(
                        'Return',

                        style:
                            TextStyle(
                          color:
                              Colors
                                  .white,
                        ),
                      ),

                      Text(
                        widget.returnLabel,

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,

                          color:
                              widget.profit
                                  ? Colors
                                      .limeAccent
                                  : Colors
                                      .redAccent,
                        ),
                      ),
                    ],
                  ),

                  AnimatedRotation(
                    turns:
                        expanded
                            ? .5
                            : 0,

                    duration:
                        const Duration(
                      milliseconds:
                          250,
                    ),

                    child:
                        const Icon(
                      Icons
                          .keyboard_arrow_down,

                      color:
                          Colors
                              .white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration:
                const Duration(
              milliseconds:
                  250,
            ),

            crossFadeState:
                expanded
                    ? CrossFadeState
                        .showSecond
                    : CrossFadeState
                        .showFirst,

            firstChild:
                const SizedBox(),

            secondChild:
                Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.black
                        .withOpacity(
                          .12,
                        ),

                borderRadius:
                    const BorderRadius.vertical(
                  bottom:
                      Radius.circular(
                    14,
                  ),
                ),
              ),

              child:
                  widget.trade ==
                          null
                      ? Column(
                          children: [
                            row(
                              'Date',
                              formatTradeTabDate(
                                widget
                                    .date,
                              ),
                            ),

                            row(
                              'Return',
                              widget
                                  .returnLabel,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            row(
                              'Hit Price',
                              fmt(
                                widget
                                    .trade
                                    ?.hitPrice,
                              ),
                            ),

                            row(
                              'Target',
                              fmt(
                                widget
                                    .trade
                                    ?.upperPrice,
                              ),
                            ),

                            row(
                              'Stop Loss',
                              fmt(
                                widget
                                    .trade
                                    ?.lowerPrice,
                              ),
                            ),

                            row(
                              'Created',
                              widget
                                      .trade
                                      ?.displayCreatedAt ??
                                  '',
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget row(
    String l,
    String v,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 100,

            child: Text(
              l,

              style:
                  const TextStyle(
                color:
                    Colors
                        .white70,
              ),
            ),
          ),

          Expanded(
            child: Text(
              v,

              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}