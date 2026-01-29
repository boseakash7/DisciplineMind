import 'package:discipline_mind/ui/main_home/alert_main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/main_home_controller.dart';

class MainHomeScreen extends StatelessWidget {
  final MainNavigationController navLayoutController = Get.put(
    MainNavigationController(),
  );
  final List<Widget> screens = [
    AlertsMainScreen(),
    Center(child: Text("Home Screen")),
    Center(child: Text("Chat Screen")),
    Center(child: Text("Analysis Screen")),
    Center(child: Text("Profile Screen")),
  ];

  MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: navLayoutController.selectedIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          currentIndex: navLayoutController.selectedIndex.value,
          onTap: (index) => navLayoutController.changeIndex(index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment, color: Colors.blue),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.touch_app_outlined),
              activeIcon: Icon(Icons.touch_app, color: Colors.blue),
              label: "Action",
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                backgroundColor: Colors.green,
                radius: 25,
                child: Icon(Icons.psychology, color: Colors.white, size: 30),
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics, color: Colors.blue),
              label: "Analysis",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: Colors.blue),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
