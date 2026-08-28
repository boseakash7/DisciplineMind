import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/ui/main_home/analysis_screen.dart';
import 'package:discipline_mind/ui/main_home/bm_screen.dart';
import 'package:discipline_mind/ui/main_home/chat_screen.dart';
import 'package:discipline_mind/ui/main_home/more_screen.dart';
import 'package:discipline_mind/ui/main_home/trade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MainHomeScreen extends StatefulWidget {
  final int initialIndex;

  const MainHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _openMoreTab() {
    setState(() => currentIndex = 4);
  }

  void _onTabSelected(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBarColor = theme.bottomNavigationBarTheme.backgroundColor ??
        (isDark ? const Color(0xFF1E222A) : Colors.white);

    const navBarHeight = 64.0;
    const fabSize = 54.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final screens = [
      BmScreen(onMonkkTap: _openMoreTab, isActive: currentIndex == 0),
      TradesScreen(onMonkkTap: _openMoreTab, isActive: currentIndex == 1),
      ChatScreen(onMonkkTap: _openMoreTab, isActive: currentIndex == 2),
      AnalysisScreen(onMonkkTap: _openMoreTab, isActive: currentIndex == 3),
      const MoreScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final textColor = isDark ? Colors.white : const Color(0xFF10122D);
              final subTextColor = isDark ? Colors.white60 : const Color(0xFF70717F);
              final headerBg = isDark ? const Color(0xFF14171D) : Colors.white;

              return Container(
                color: headerBg,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final user = Common.userData.value?.payload;
                            final rawName = (user?.fullName ?? user?.phone ?? '').trim();
                            final userName = rawName.isNotEmpty ? rawName : 'User';
                            final avatarLetter = rawName.isNotEmpty
                                ? rawName[0].toUpperCase()
                                : 'U';

                            return Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF2C3240)
                                        : const Color(0xFFF3F0FF),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatarLetter,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        "Have a good Day !",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        body: KeyedSubtree(
          key: ValueKey(theme.brightness),
          child: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: navBarHeight + fabSize / 2 + bottomInset,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Bottom Nav Bar Background
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: navBarHeight + bottomInset,
                  decoration: BoxDecoration(
                    color: navBarColor,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentIndex,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: isDark
                        ? const Color(0xFF8E95A5)
                        : const Color(0xFF70717F),
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

              // Floating Central AI Action Button
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
                        color: currentIndex == 2
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
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
      ),
    );
  }
}