import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_project/modules/quiz/controllers/quiz_session_controller.dart';

class QuizSessionScreen extends StatefulWidget {
  const QuizSessionScreen({super.key});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  late final QuizSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<QuizSessionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final currentQuestion = _controller.currentQuestion.value;
          final currentDisplay = _controller.isCompleted.value
              ? _controller.askedCount.value
              : (_controller.askedCount.value + (currentQuestion == null ? 0 : 1));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Duel Code: MCQPLAY',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A3A58),
                        ),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D66E6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_controller.questionLimit - _controller.askedCount.value}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question $currentDisplay of ${_controller.questionLimit}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4D5B79),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _controller.progressFraction,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: const Color(0xFFE3E8F4),
                      color: const Color(0xFFBE39D7),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading.value && _controller.currentQuestion.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.isCompleted.value) {
      final score = _controller.correctCount.value;
      final total = _controller.askedCount.value;
      final percent = total == 0 ? 0 : ((score / total) * 100).round();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quiz Completed',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$score / $total correct',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  color: const Color(0xFF3C4F73),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Accuracy: $percent%',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2163DF),
                ),
              ),
              if (_controller.lastExplanation.value.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E6FE)),
                  ),
                  child: Text(
                    _controller.lastExplanation.value,
                    style: GoogleFonts.poppins(color: const Color(0xFF304870)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2065E4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final error = _controller.errorMessage.value;
    final question = _controller.currentQuestion.value;
    if (question == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error.isEmpty ? 'No question available' : error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF48597A),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _controller.startSession,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question No. #${question.questionIndex}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4D5B79),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EAF8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D142850),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question.text,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2944),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.map(
            (option) => _optionTile(
              id: option.id,
              text: option.text,
              selected: _controller.selectedOptionId.value == option.id,
            ),
          ),
          if (_controller.errorMessage.value.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage.value,
              style: GoogleFonts.poppins(color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile({
    required String id,
    required String text,
    required bool selected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _controller.isSubmitting.value ? null : () => _controller.submitOption(id),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF2A68E6) : const Color(0xFFE0E7F4),
                width: selected ? 1.6 : 1.0,
              ),
              color: selected ? const Color(0xFFEFF4FF) : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF2A68E6) : const Color(0xFFAAB7CF),
                    ),
                    color: selected ? const Color(0xFF2A68E6) : Colors.transparent,
                  ),
                  child: Text(
                    id,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF5D6D8B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF253451),
                    ),
                  ),
                ),
                if (_controller.isSubmitting.value && selected)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
