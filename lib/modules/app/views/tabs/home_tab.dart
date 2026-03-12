import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/progress/controllers/progress_controller.dart';
import 'package:test_project/routes/app_routes.dart';

class HomeTab extends GetView<AppStateController> {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final progressController = Get.find<ProgressController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${controller.selectedPath.value?.title ?? 'Aspirant'}!',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF18253D),
                            ),
                          ),
                          Text(
                            'Ready to test your knowledge?',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: const Color(0xFF6A768E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE6ECF8),
                      child: Text(
                        _avatarLetter(controller.selectedPath.value?.title ?? 'S'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF274678),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _dailyGoalCard(),
                const SizedBox(height: 20),
                Text(
                  'Setup Your Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF192846),
                  ),
                ),
                const SizedBox(height: 14),
                _examField(),
                const SizedBox(height: 16),
                Text(
                  'Subject',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF33456A),
                  ),
                ),
                const SizedBox(height: 10),
                if (controller.isSubjectsLoading.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    ),
                  )
                else if (controller.subjects.isEmpty)
                  Text(
                    controller.subjectsError.value.isEmpty
                        ? 'No subjects available for this exam'
                        : controller.subjectsError.value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6A768E),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: controller.subjects
                        .map(
                          (subject) => _choicePill(
                            label: _capitalize(subject),
                            selected: controller.selectedSubject.value == subject,
                            onTap: () => controller.setSubject(subject),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 14),
                Text(
                  'Difficulty',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF33456A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.difficulties
                      .map(
                        (difficulty) => _choicePill(
                          label: _capitalize(difficulty),
                          selected:
                              controller.selectedDifficulty.value == difficulty,
                          activeColor: const Color(0xFF111F35),
                          onTap: () => controller.setDifficulty(difficulty),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!controller.hasSelectedPath) {
                        Get.toNamed(AppRoutes.pathSelection);
                        return;
                      }
                      if (controller.selectedSubject.value.isEmpty) {
                        Get.snackbar(
                          'Subject required',
                          'No subject available for selected exam yet.',
                        );
                        return;
                      }
                      Get.toNamed(AppRoutes.quizSession);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F67E6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Start Quiz',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _quickProgress(progressController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dailyGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C67E8), Color(0xFF224EC4)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x282862E6),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.todayAnswered.value} / ${controller.dailyTarget.value}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Questions answered today',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _examField() {
    final selectedTitle = controller.selectedPath.value?.title ?? 'Choose path';

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.pathSelection),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE5F4)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: Color(0xFF4367A3)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E2A42),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _choicePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF1A64E6),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFDEE5F1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3B4A66),
          ),
        ),
      ),
    );
  }

  Widget _quickProgress(ProgressController progressController) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF8FAFF),
          border: Border.all(color: const Color(0xFFE0E8F7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solved: ${progressController.progress.value.totalSolved}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF30466E),
              ),
            ),
            Text(
              'Correct: ${progressController.progress.value.correctAnswers}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF30466E),
              ),
            ),
            Text(
              '${(progressController.progress.value.accuracy * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E66E6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  String _avatarLetter(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'S';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}
