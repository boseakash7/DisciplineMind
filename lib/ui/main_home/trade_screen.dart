import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';

class TradesScreen extends StatelessWidget {
  const TradesScreen({super.key});

  Widget tradeCard(bool profit) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.white),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "SENSEX05MARCH84000 CE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Date - ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "20-04-2026",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Return",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                profit ? "12.5%" : "-14.25%",
                style: TextStyle(
                  color: profit ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),

          const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget overviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Total Trades : 120"), Text("Total Wins : 97")],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Trade Accuracy : 80.33 %"),

                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(width: 6, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Column(
              children: [
                Text(
                  "RETURNS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("FRR - 25%", style: TextStyle(color: Colors.white)),
                    Text("RTT - 97 %", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Monkk",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                Row(
                  children: [
                    const Text(
                      "Credits : 250",
                      style: TextStyle(color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    CircleAvatar(radius: 12),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  value: "Drop Down with values",
                  items: [
                    DropdownMenuItem(
                      value: "Drop Down with values",
                      child: Text("Drop Down with values"),
                    ),
                  ],
                  onChanged: null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Believe Mode Trades Overview",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            overviewCard(),

            const SizedBox(height: 25),

            const Text(
              "Per Trade Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            tradeCard(true),
            tradeCard(true),
            tradeCard(false),
          ],
        ),
      ),
    );
  }
}
