import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/v2_app_colors.dart';
import '../../common/v2_common.dart';
import '../../../services/app_data_refresh_service.dart';
import 'v2_analysis_screen.dart';
import 'v2_bm_screen.dart';
import 'v2_chat_screen.dart';
import 'v2_more_screen.dart';
import 'v2_trade_screen.dart';

class V2MainHomeScreen extends StatefulWidget {
  final int initialIndex;

  const V2MainHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<V2MainHomeScreen> createState() => _V2MainHomeScreenState();
}

class _V2MainHomeScreenState extends State<V2MainHomeScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _openMoreTab() => setState(() => currentIndex = 4);

  void _onTabSelected(int index) {
    setState(() => currentIndex = index);
    final userId = V2Common.userId;
    if (userId.isEmpty) return;

    final refresh = Get.isRegistered<AppDataRefreshService>()
        ? Get.find<AppDataRefreshService>()
        : Get.put(AppDataRefreshService(), permanent: true);
    unawaited(refresh.refreshIfNeeded(force: true));
  }

  @override
  Widget build(BuildContext context) {
    const navBarHeight = 70.0;
    const fabSize = 56.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final screens = [
      V2BmScreen(
        onMonkkTap: _openMoreTab,
        isActive: currentIndex == 0,
      ),
      V2TradesScreen(
        onMonkkTap: _openMoreTab,
        isActive: currentIndex == 1,
      ),
      V2ChatScreen(
        onMonkkTap: _openMoreTab,
        isActive: currentIndex == 2,
      ),
      V2AnalysisScreen(
        onMonkkTap: _openMoreTab,
        isActive: currentIndex == 3,
      ),
      const V2MoreScreen(),
    ];

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300 && currentIndex < 4) {
            _onTabSelected(currentIndex + 1);
          } else if (details.primaryVelocity! > 300 && currentIndex > 0) {
            _onTabSelected(currentIndex - 1);
          }
        },
        child: IndexedStack(index: currentIndex, children: screens),
      ),
      bottomNavigationBar: SizedBox(
        height: navBarHeight + fabSize / 2 + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: navBarHeight + bottomInset,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: currentIndex,
                  selectedItemColor: V2AppColors.primary,
                  unselectedItemColor: Colors.grey.shade500,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    height: 1.1,
                  ),
                  iconSize: 22,
                  elevation: 0,
                  onTap: _onTabSelected,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_outlined),
                      activeIcon: Icon(Icons.grid_view),
                      label: "BM",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.swap_vert),
                      activeIcon: Icon(Icons.swap_vert),
                      label: "Trades",
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox(height: 24, width: 24),
                      label: "",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart_outlined),
                      activeIcon: Icon(Icons.bar_chart),
                      label: "Analysis",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu),
                      label: "More",
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _onTabSelected(2),
                  child: Container(
                    height: fabSize,
                    width: fabSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          V2AppColors.primary,
                          V2AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: V2AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
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
            ),
          ],
        ),
      ),
    );
  }
}
