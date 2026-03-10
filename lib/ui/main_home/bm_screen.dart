import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';

class BmScreen extends StatelessWidget {
  const BmScreen({super.key, this.onMonkkTap});

  final VoidCallback? onMonkkTap;

  /// Highest level index achieved (0=BM, 1=AP, 2=AO, 3=AA, 4=AI)
  static const int achievedLevelIndex = 0;

  Widget modeCard({
    required String title,
    required Color color,
    required bool isAchieved,
    required bool isFirstCard,
    String frr = "",
    String rtt = "",
    String trades = "",
    String wins = "",
    String returns = "",
    String cmReturns = "",
    String risk = "",
    String reward = "",
  }) {
    final effectiveColor = isAchieved
        ? color
        : Color.lerp(color, Colors.white, 0.35)!;
    final bgOpacity = isAchieved ? 0.0 : 0.1;
    final textColor = isFirstCard
        ? Colors.white
        : (isAchieved ? Colors.black87 : Colors.grey.shade600);
    final iconColor = isFirstCard ? Colors.white : effectiveColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAchieved
            ? effectiveColor
            : effectiveColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(1),
        // border: Border.all(
        //   color: isAchieved
        //       ? effectiveColor.withOpacity(0.4)
        //       : effectiveColor.withOpacity(0.5),
        //   width: isAchieved ? 1.5 : 1,
        // ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  isFirstCard
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "FRR",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              " - $frr",
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "RTT",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              " - $rtt",
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                          ],
                        )
                      : Text(
                          "FRR - $frr${rtt.isNotEmpty ? "     RTT - $rtt" : ""}",
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                  if (isFirstCard)
                    Text(
                      "Trades - $trades     Wins - $wins",
                      style: TextStyle(color: textColor, fontSize: 13),
                    )
                  else if (wins.isNotEmpty)
                    Text(
                      "Trades - $trades     Wins - $wins",
                      style: TextStyle(color: textColor, fontSize: 13),
                    )
                  else
                    Text(
                      "Trades - $trades",
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),

                  if (risk.isNotEmpty && reward.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Risk - $risk",
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                    Text(
                      "Reward - $reward",
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],

                  if (returns.isNotEmpty || cmReturns.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "My Returns - $returns    CM Returns - $cmReturns",
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 28,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isAchieved ? Colors.white : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: isAchieved
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: isAchieved
                        ? (isFirstCard ? Colors.white : iconColor)
                        : Colors.grey.shade600,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelIndicator(String text, Color color, {required bool isAchieved}) {
    final effectiveColor = isAchieved
        ? color
        : Color.lerp(color, Colors.white, 0.35)!;
    final bgColor = isAchieved
        ? color.withOpacity(0.2)
        : effectiveColor.withOpacity(0.25);
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onMonkkTap,
                  child: const Text(
                    "Monkk",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                Row(
                  children: const [
                    Text(
                      "Credits: 250",
                      style: TextStyle(color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    CircleAvatar(radius: 12, backgroundColor: Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Achievement Levels",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Timeline.tileBuilder(
                theme: TimelineThemeData(nodePosition: 0),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  contentsAlign: ContentsAlign.basic,
                  contentsBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildCardForIndex(index),
                  ),
                  connectorBuilder: (context, index, type) {
                    final isAchieved = index == 0
                        ? achievedLevelIndex >= 0
                        : achievedLevelIndex >= index - 1;
                    return DashedLineConnector(
                      color: isAchieved ? Colors.black : Colors.grey.shade300,
                    );
                  },
                  indicatorBuilder: (context, index) => ContainerIndicator(
                    child: _levelIndicator(
                      ["BM", "AP", "AO", "AA", "AI"][index],
                      [
                        AppColors.primary,
                        Colors.purple,
                        Colors.green,
                        Colors.orange,
                        Colors.indigo,
                      ][index],
                      isAchieved: achievedLevelIndex >= index,
                    ),
                  ),
                  itemCount: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForIndex(int index) {
    switch (index) {
      case 0:
        return modeCard(
          title: "Believe Mode",
          color: AppColors.primary,
          isAchieved: achievedLevelIndex >= 0,
          isFirstCard: true,
          frr: "80%",
          rtt: "20%",
          trades: "0",
          wins: "0",
          returns: "120%",
          cmReturns: "145%",
        );
      case 1:
        return modeCard(
          title: "Achieve Purple",
          color: Colors.purple,
          isAchieved: achievedLevelIndex >= 1,
          isFirstCard: false,
          frr: "100%",
          trades: "XX",
          wins: "XX",
          risk: "Rs. 550 to 1050",
          reward: "Rs. 550 to Unlimited",
          returns: "XX",
          cmReturns: "XX",
        );
      case 2:
        return modeCard(
          title: "Achieve Olive",
          color: Colors.green,
          isAchieved: achievedLevelIndex >= 2,
          isFirstCard: false,
          frr: "100%",
          trades: "XX",
          returns: "XX",
          cmReturns: "XX",
        );
      case 3:
        return modeCard(
          title: "Achieve Amber",
          color: Colors.orange,
          isAchieved: achievedLevelIndex >= 3,
          isFirstCard: false,
          frr: "100%",
          trades: "XX",
          returns: "XX",
          cmReturns: "XX",
        );
      case 4:
        return modeCard(
          title: "Achieve Indigo",
          color: Colors.indigo,
          isAchieved: achievedLevelIndex >= 4,
          isFirstCard: false,
          frr: "100%",
          trades: "XX",
          returns: "XX",
          cmReturns: "XX",
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
