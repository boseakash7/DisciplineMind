import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/ui/main_home/analysis_screen.dart';
import 'package:discipline_mind/ui/main_home/bm_screen.dart';
import 'package:discipline_mind/ui/main_home/chat_screen.dart';
import 'package:discipline_mind/ui/main_home/more_screen.dart';
import 'package:discipline_mind/ui/main_home/trade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBarColor = theme.bottomNavigationBarTheme.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : Colors.white);

    const navBarHeight = 70.0;
    const fabSize = 62.0;
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
          preferredSize: const Size.fromHeight(86),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final textColor = isDark ? Colors.white : Colors.black;
              final subTextColor = isDark ? Colors.white60 : Colors.black54;

              return Container(
                color: theme.scaffoldBackgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              "S",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Vikas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 2),
                              Text("Have a good Day !", style: TextStyle(fontSize: 13, color: subTextColor)),
                            ],
                          ),
                        ),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                                child: const Icon(Icons.monetization_on, color: Colors.orange, size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text("250", style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                            ],
                          ),
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
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Background Bar
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
                        blurRadius: 12,
                        color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "BM"),
                        _buildNavItem(1, Icons.swap_horiz_outlined, Icons.swap_horiz, "Trades"),
                        const SizedBox(width: 60), // Space for FAB
                        _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, "Analysis"),
                        _buildNavItem(4, Icons.menu_outlined, Icons.menu, "More"),
                      ],
                    ),
                  ),
                ),
              ),

              // Glowing Center FAB
              Positioned(
                bottom: navBarHeight / 2 - fabSize / 2 + bottomInset +10,
                child: GestureDetector(
                  onTap: () => setState(() => currentIndex = 2),
                  child: Container(
                    width: fabSize,
                    height: fabSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          spreadRadius: 2,
                          color: const Color(0xFF00D4FF).withOpacity(0.6),
                        ),
                      ],
                    ),
                    child:Stack(
                      children: [
                        Positioned(top: 6,right: 10,
                          child:Image.asset("assets/star.png",height: 30,)
                        ),
                        Positioned(
                          top: 30,left:10,
                          child: Image.asset("assets/star.png",height: 20,)
                        ),
                      ],
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : (isDark ? Color(0xFF64748B) :Color(0xFF64748B)),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? Color(0xFF64748B) : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}