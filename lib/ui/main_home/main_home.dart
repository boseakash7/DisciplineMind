import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/ui/main_home/trade_screen.dart';
import 'package:flutter/material.dart';

import 'bm_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int currentIndex = 0;

  final screens = [
    const BmScreen(),
    const TradesScreen(),
    const Center(child: Text("Action")),
    const Center(child: Text("Analysis")),
    const Center(child: Text("More")),
  ];

  @override
  Widget build(BuildContext context) {
    const navBarHeight = 70.0;
    const fabSize = 56.0;

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: navBarHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view),
                  label: "BM",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.swap_vert),
                  activeIcon: Icon(Icons.swap_vert),
                  label: "Trades",
                ),
                const BottomNavigationBarItem(
                  icon: SizedBox(height: 24, width: 24),
                  label: "",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: "Analysis",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: "More",
                ),
              ],
            ),
          ),
          Positioned(
            top: -fabSize / 2 + 4,
            child: GestureDetector(
              onTap: () => setState(() => currentIndex = 2),
              child: Container(
                height: fabSize,
                width: fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentIndex == 2
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
