import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class QuizController extends GetxController {
  // UI State
  var isLoading = false.obs;
  var errorMessage = RxnString();

  // Configuration State
  final inputController = TextEditingController();
  var selectedType = 'Topic'.obs; // Topic, Link, Text
  var selectedSector = 'Banking'.obs;
  var selectedExam = 'IBPS PO'.obs;
  var selectedSubject = 'Quant'.obs;
  var selectedTopic = 'Percentage'.obs;
  var selectedLanguage = 'English'.obs;
  var difficulty = 'Medium'.obs;
  var numQuestions = 5.0.obs;

  // Gameplay State
  var isShowingPlayground = false.obs;
  var isQuizActive = false.obs;
  var isQuizFinished = false.obs;
  var isReviewing = false.obs;
  var currentQuestionIndex = 0.obs;
  var score = 0.obs;
  var questions = <dynamic>[].obs;
  var userAnswers = <int?>[].obs;

  // Timer State
  Timer? _questionTimer;
  var remainingSeconds = 0.obs;

  // Logo Animation State (Playground)
  Timer? _logoTimer;
  var currentLogoIndex = 0.obs;
  final List<IconData> gameLogos = [
    Icons.sports_esports,
    Icons.videogame_asset,
    Icons.casino,
    Icons.auto_awesome,
    Icons.rocket_launch,
  ];

  // Data Maps (Configuration)
  final Map<String, List<String>> examSectors = {
    'Banking': ['IBPS PO', 'SBI PO', 'RBI Grade B', 'IBPS Clerk'],
    'SSC': ['SSC CGL', 'SSC CHSL', 'SSC MTS', 'SSC GD'],
    'UPSC': ['CSE (IAS)', 'CDS', 'CAPF', 'EPFO'],
    'Railway': ['RRB NTPC', 'RRB Group D', 'RRB ALP'],
    'Defence': ['AFCAT', 'NDA', 'Indian Army'],
    'Teaching': ['CTET', 'UGC NET', 'KVS'],
    'State PSC': ['UPPSC', 'BPSC', 'MPSC', 'RAS'],
    'Police': ['Delhi Police', 'UP Police', 'Bihar Police'],
  };

  final List<String> subjects = ['Quant', 'Reasoning', 'English', 'GA/GS'];

  final Map<String, List<String>> subjectTopics = {
    'Quant': ['Percentage', 'Ratio', 'Algebra', 'Trigonometry', 'Geometry'],
    'Reasoning': ['Puzzles', 'Syllogism', 'Blood Relations', 'Coding-Decoding'],
    'English': ['Reading Comp', 'Cloze Test', 'Para Jumbles', 'Error Spotting'],
    'GA/GS': ['Current Affairs', 'History', 'Polity', 'Geography', 'Science'],
  };

  final List<String> languages = [
    'Assamese',
    'Bengali',
    'Bodo',
    'Dogri',
    'Gujarati',
    'Hindi',
    'Kannada',
    'Kashmiri',
    'Konkani',
    'Maithili',
    'Malayalam',
    'Manipuri (Meitei)',
    'Marathi',
    'Nepali',
    'Odia (Oriya)',
    'Punjabi',
    'Sanskrit',
    'Santali',
    'Sindhi',
    'Tamil',
    'Telugu',
    'Urdu',
    'English',
  ];

  @override
  void onClose() {
    _questionTimer?.cancel();
    _logoTimer?.cancel();
    inputController.dispose();
    super.onClose();
  }

  // --- Actions ---

  void setType(String type) => selectedType.value = type;
  void setSector(String sector) {
    selectedSector.value = sector;
    selectedExam.value = examSectors[sector]!.first;
  }

  void setExam(String exam) => selectedExam.value = exam;
  void setSubject(String subject) {
    selectedSubject.value = subject;
    selectedTopic.value = subjectTopics[subject]!.first;
  }

  void setTopic(String topic) => selectedTopic.value = topic;
  void setLanguage(String lang) => selectedLanguage.value = lang;
  void setDifficulty(String diff) => difficulty.value = diff;
  void setNumQuestions(double val) => numQuestions.value = val;

  Future<void> generateQuiz() async {
    final input = inputController.text.trim();
    if (selectedType.value != 'Topic' && input.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter content to transform!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    questions.clear();
    isQuizActive.value = false;

    try {
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://localhost:5001';
      } else if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:5001';
      } else {
        baseUrl = 'http://127.0.0.1:5001';
      }

      final url = Uri.parse('$baseUrl/generate_quiz');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': selectedType.value == 'Topic' ? selectedTopic.value : input,
          'num_questions': numQuestions.value.toInt(),
          'difficulty': difficulty.value,
          'input_type': selectedType.value.toLowerCase(),
          'language': selectedLanguage.value,
          'exam_sector': selectedSector.value,
          'exam_name': selectedExam.value,
          'subject': selectedSubject.value,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        questions.assignAll(data);
        if (data.isNotEmpty) {
          _showPlaygroundTransition();
        }
      } else {
        errorMessage.value = 'Failed: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _showPlaygroundTransition() async {
    isShowingPlayground.value = true;
    isQuizActive.value = false;
    currentLogoIndex.value = 0;

    _logoTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      currentLogoIndex.value = (currentLogoIndex.value + 1) % gameLogos.length;
    });

    await Future.delayed(const Duration(seconds: 3));

    _logoTimer?.cancel();
    isShowingPlayground.value = false;
    startQuiz();
  }

  void startQuiz() {
    isQuizActive.value = true;
    isQuizFinished.value = false;
    isReviewing.value = false;
    currentQuestionIndex.value = 0;
    score.value = 0;
    userAnswers.assignAll(List.filled(questions.length, null));
    startTimer();
  }

  int _getTimerDuration() {
    switch (selectedSector.value) {
      case 'Banking':
        return 35;
      case 'SSC':
        return 45;
      case 'UPSC':
        return 90;
      default:
        return 60;
    }
  }

  void startTimer() {
    _questionTimer?.cancel();
    remainingSeconds.value = _getTimerDuration();

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _questionTimer?.cancel();
        handleOptionSelected(-1);
      }
    });
  }

  void handleOptionSelected(int index) {
    _questionTimer?.cancel();
    userAnswers[currentQuestionIndex.value] = index;
    // userAnswers.refresh(); // Not strictly needed as we assign to index, but with RxList sometimes imperative updates need refresh? No, usually list[i]=x triggers update if using valid index or .assignAll.
    // Actually RxList modification by index might require .refresh() or creating new list. Let's use .refresh() or recreate list copy to be safe.
    userAnswers.refresh();

    Future.delayed(const Duration(milliseconds: 300), () {
      nextQuestion();
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      startTimer();
    } else {
      finishQuiz();
    }
  }

  void finishQuiz() {
    _calculateScore();
    isQuizActive.value = false;
    isQuizFinished.value = true;
  }

  void _calculateScore() {
    int calculatedScore = 0;
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswerIndex = userAnswers[i];
      if (userAnswerIndex != null && userAnswerIndex != -1) {
        final selectedOption = question['options'][userAnswerIndex];
        if (selectedOption == question['answer']) {
          calculatedScore++;
        }
      }
    }
    score.value = calculatedScore;
  }

  void retryQuiz() {
    startQuiz();
  }

  void startNewQuiz() {
    questions.clear();
    isQuizActive.value = false;
    isQuizFinished.value = false;
    errorMessage.value = null;
    isReviewing.value = false;
  }

  void enterReviewMode() {
    isReviewing.value = true;
  }

  void exitReviewMode() {
    isReviewing.value = false;
  }
}
