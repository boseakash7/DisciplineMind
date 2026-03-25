import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/ui/main_home/alert_main.dart';
import 'package:discipline_mind/ui/main_home/chat_screen.dart';
import 'package:discipline_mind/ui/main_home/trade_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bm_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int currentIndex = 0;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    const navBarHeight = 70.0;
    const fabSize = 56.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final screens = [
      BmScreen(onMonkkTap: _openDrawer),
      TradesScreen(onMonkkTap: _openDrawer),
      ChatScreen(onMonkkTap: _openDrawer),
      const Center(child: Text("Analysis")),
      const Center(child: Text("More")),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Obx(() {
                final name = Common.userData.value?.payload?.fullName ??
                    Common.userData.value?.payload?.email ??
                    'User';
                return Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Price Alerts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertsMainScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Common.logout();
              },
            ),
          ],
        ),
      ),
      body: screens[currentIndex],

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
                  selectedLabelStyle: const TextStyle(fontSize: 11, height: 1.1),
                  unselectedLabelStyle:
                      const TextStyle(fontSize: 11, height: 1.1),
                  iconSize: 22,
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
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
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
            ),
          ],
        ),
      ),
    );
  }
}
