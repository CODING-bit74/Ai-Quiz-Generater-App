import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/modules/app/controllers/main_nav_controller.dart';
import 'package:test_project/modules/app/views/tabs/duel_tab.dart';
import 'package:test_project/modules/app/views/tabs/home_tab.dart';
import 'package:test_project/modules/app/views/tabs/profile_tab.dart';
import 'package:test_project/modules/app/views/tabs/progress_tab.dart';

class MainShellScreen extends GetView<MainNavController> {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const HomeTab(),
      const DuelTab(),
      const ProgressTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.selectedIndex.value,
            children: tabs,
          )),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0x1F2A64E8),
          destinations: [
            _destination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
            _destination(icon: Icons.flash_on_outlined, selectedIcon: Icons.flash_on, label: 'Duel'),
            _destination(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Progress'),
            _destination(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _destination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
      tooltip: label,
    );
  }
}
