import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/path/controllers/path_selection_controller.dart';

class PathSelectionScreen extends GetView<PathSelectionController> {
  const PathSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Get.find<AppStateController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF163868), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x110F2142),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 18),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F65E4),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Choose Your Path',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111D36),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select the exam you're preparing for",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF5D6780),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Obx(() {
                        if (appState.isExamPathsLoading.value) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (appState.examPaths.isEmpty) {
                          return Center(
                            child: Text(
                              appState.examPathsError.value.isEmpty
                                  ? 'No exam paths available'
                                  : appState.examPathsError.value,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF667288),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: appState.examPaths.length,
                          itemBuilder: (context, index) {
                            final item = appState.examPaths[index];
                            final color = _chipColor(index);
                            final isSelected =
                                controller.selectedPathId.value == item.id;
                            return _PathItemTile(
                              title: item.title,
                              subtitle: item.subtitle,
                              color: color,
                              selected: isSelected,
                              onTap: () => controller.selectPath(item.id),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: controller.continueToApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4674C9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You can change this later in settings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF74819A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _chipColor(int index) {
    const colors = [
      Color(0xFF1D67DA),
      Color(0xFF7E3DCE),
      Color(0xFF23A063),
      Color(0xFFCB3158),
    ];
    return colors[index % colors.length];
  }
}

class _PathItemTile extends StatelessWidget {
  const _PathItemTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF2F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFF3A6DD5) : const Color(0xFFE8EDF6),
          width: selected ? 1.6 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101A34),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A243A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF667288),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2462DE),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
