import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/modules/progress/controllers/progress_controller.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final progressController = Get.find<ProgressController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(
          () {
            final progress = progressController.progress.value;
            final accuracy = progress.accuracy;
            final accuracyPercent = (accuracy * 100).round();

            return RefreshIndicator(
              onRefresh: progressController.fetchProgress,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17253D),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4ECF9)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: accuracy == 0 ? 0.01 : accuracy,
                                strokeWidth: 14,
                                backgroundColor: const Color(0xFFDCE8FD),
                                color: const Color(0xFF1C66E4),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$accuracyPercent%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF102340),
                                    ),
                                  ),
                                  Text(
                                    'Accuracy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6A7894),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          icon: Icons.tag_outlined,
                          value: '${progress.totalSolved}',
                          label: 'TOTAL SOLVED',
                          iconColor: const Color(0xFF5663DF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          icon: Icons.check_circle_outline,
                          value: '${progress.correctAnswers}',
                          label: 'CORRECT',
                          iconColor: const Color(0xFF28A266),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          icon: Icons.local_fire_department_outlined,
                          value: '${(accuracyPercent / 7).round()}',
                          label: 'DAY STREAK',
                          iconColor: const Color(0xFFE65454),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          icon: Icons.show_chart_rounded,
                          value: accuracyPercent >= 80 ? 'Top 5%' : 'Top 35%',
                          label: 'RANKING',
                          iconColor: const Color(0xFF9044D9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111F36),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Challenge',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Solve 50 questions',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${progress.totalSolved > 50 ? 50 : progress.totalSolved}/50',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFFAA49),
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progressController.errorMessage.value.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      progressController.errorMessage.value,
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15253F),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6F7D95),
            ),
          ),
        ],
      ),
    );
  }
}
