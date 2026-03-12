import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/routes/app_routes.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final appStateController = Get.find<AppStateController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(
          () {
            final user = authController.user.value;
            final displayName = (user?.name ?? '').trim().isNotEmpty
                ? user!.name
                : (user?.email ?? 'User');

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16253E),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE1E9F7)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE7EFFD),
                        child: Text(
                          _avatarLetter(displayName),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF335387),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: const Color(0xFF1A2A46),
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7892),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _menuTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Change Exam Path',
                  onTap: () => Get.toNamed(AppRoutes.pathSelection),
                ),
                _menuTile(
                  icon: Icons.school_outlined,
                  title:
                      'Current Path: ${appStateController.selectedPath.value?.title ?? 'Not selected'}',
                  onTap: () => Get.toNamed(AppRoutes.pathSelection),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authController.logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D61DE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2EAF8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3D5D95)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF253450),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _avatarLetter(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'U';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}
