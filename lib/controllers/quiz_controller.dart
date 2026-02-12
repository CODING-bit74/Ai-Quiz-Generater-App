import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/history_model.dart';
import '../services/database_service.dart';
import 'history_controller.dart';

class QuizController extends GetxController {
  // --- UI & ERROR STATE (GETX OBSERVABLES) ---

  // Controls the overall loading state during API calls or file processing
  var isLoading = false.obs;
  // Holds any error message that needs to be displayed in the UI
  var errorMessage = RxnString();
  // Dynamic message shown to the user during loading/processing
  var loadingMessage = "CRAFTING YOUR QUIZ".obs;

  // --- CONFIGURATION & TARGET STATE ---

  // Controller for the manual text/link input field on the home screen
  final inputController = TextEditingController();
  // Tracks the current input source (Topic, Link, Text, or Document)
  var selectedType = 'Topic'.obs;
  // Stores the name of the PDF file selected by the user
  var pickedFileName = RxnString();
  // Stores the local system path to the selected PDF file
  var pickedFilePath = RxnString();
  // Target Configuration: Selected Indian Exam Sector (e.g., Banking, SSC)
  var selectedSector = 'Banking'.obs;
  // Target Configuration: Specific exam within the sector (e.g., IBPS PO)
  var selectedExam = 'IBPS PO'.obs;
  // Target Configuration: Subject focus (e.g., Quant, English)
  var selectedSubject = 'Quant'.obs;
  // Target Configuration: Pre-defined specific topic based on subject
  var selectedTopic = 'Percentage'.obs;
  // UI Language for the generated quiz questions
  var selectedLanguage = 'English'.obs;
  // Difficulty level for LLM generation (Easy, Medium, Hard)
  var difficulty = 'Medium'.obs;
  // Number of questions requested from the AI
  var numQuestions = 5.0.obs;
  // Detected metadata from AI refinement
  var detectedSubject = RxnString();
  var detectedTopic = RxnString();

  // --- GAMEPLAY & SESSION STATE ---

  // State for the "Playground" entrance transition animation
  var isShowingPlayground = false.obs;
  // True when the user is actively answering a question set
  var isQuizActive = false.obs;
  // True when the quiz ends and we show the results screen
  var isQuizFinished = false.obs;
  // True when the user enters "Review Mode" to see correct answers/explanations
  var isReviewing = false.obs;
  // Tracks the current question number (0-indexed)
  var currentQuestionIndex = 0.obs;
  // The user's final score (count of correct answers)
  var score = 0.obs;
  // The actual quiz JSON data (questions, options, answers) received from API
  var questions = <dynamic>[].obs;
  // Stores the 0-indexed option choice for each question by the user
  var userAnswers = <int?>[].obs;

  // --- TIMER & ANIMATION LOGIC ---

  // Global timer for the current question
  Timer? _questionTimer;
  // Seconds remaining for the current question
  var remainingSeconds = 0.obs;

  // Transition animation for playground entrance
  Timer? _logoTimer;
  var currentLogoIndex = 0.obs;
  // List of icons rendered during the playground loading transition
  final List<IconData> gameLogos = [
    Icons.sports_esports,
    Icons.videogame_asset,
    Icons.casino,
    Icons.auto_awesome,
    Icons.rocket_launch,
  ];

  // --- DATA MAPS (CORE CONFIGURATION) ---

  // Mapping of main exam sectors to their specific common exams
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

  // Standard subjects available for all exam modes
  final List<String> subjects = ['Quant', 'Reasoning', 'English', 'GA/GS'];

  // Mapping of subjects to common high-yield topics
  final Map<String, List<String>> subjectTopics = {
    'Quant': ['Percentage', 'Ratio', 'Algebra', 'Trigonometry', 'Geometry'],
    'Reasoning': ['Puzzles', 'Syllogism', 'Blood Relations', 'Coding-Decoding'],
    'English': ['Reading Comp', 'Cloze Test', 'Para Jumbles', 'Error Spotting'],
    'GA/GS': ['Current Affairs', 'History', 'Polity', 'Geography', 'Science'],
  };

  // Comprehensive list of official Indian languages (Schedule VIII)
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
    // Cleanup timers and controllers to prevent memory leaks
    _questionTimer?.cancel();
    _logoTimer?.cancel();
    inputController.dispose();
    super.onClose();
  }

  // --- ACTIONS (UI CALLBACKS) ---

  // Updates the source type (Topic, Link, etc.)
  void setType(String type) => selectedType.value = type;

  // Updates sector and resets the exam selection to the first child of that sector
  void setSector(String sector) {
    selectedSector.value = sector;
    selectedExam.value = examSectors[sector]!.first;
  }

  // Simple setters for configuration state
  void setExam(String exam) => selectedExam.value = exam;
  void setSubject(String subject) {
    selectedSubject.value = subject;
    selectedTopic.value = subjectTopics[subject]!.first;
  }

  void setTopic(String topic) => selectedTopic.value = topic;
  void setLanguage(String lang) => selectedLanguage.value = lang;
  void setDifficulty(String diff) => difficulty.value = diff;
  void setNumQuestions(double val) => numQuestions.value = val;

  /// Triggered via the "Select Notes" button. Picks a PDF from disk.
  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.first;
        // Enforce a strict file size ceiling and floor for processing stability
        final sizeInBytes = file.size;
        if (sizeInBytes < 5 * 1024 || sizeInBytes > 200 * 1024 * 1024) {
          Get.snackbar(
            'Invalid File Size',
            'Please select a PDF between 5KB and 200MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orangeAccent,
          );
          return;
        }

        pickedFileName.value = file.name;
        pickedFilePath.value = file.path;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick file: $e');
    }
  }

  /// Internal method to send the picked PDF to the Flask backend for indexing.
  Future<bool> _uploadDocument() async {
    if (pickedFilePath.value == null) return false;

    try {
      // Determine local URL based on platform/runtime
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://localhost:5001';
      } else if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:5001';
      } else {
        baseUrl = 'http://127.0.0.1:5001';
      }

      // Construct a Multipart request for file transmission
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_document'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', pickedFilePath.value!),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage.value = 'Upload Failed: ${response.body}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Upload Error: $e';
      return false;
    }
  }

  /// Main entry point for the quiz generation flow.
  Future<void> generateQuiz() async {
    final input = inputController.text.trim();

    // Step 1: Validation
    if (selectedType.value != 'Topic' &&
        selectedType.value != 'Document' &&
        input.isEmpty) {
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
    loadingMessage.value = "CRAFTING YOUR QUIZ";
    errorMessage.value = null;
    questions.clear();
    isQuizActive.value = false;

    // Step 2: Handle Background Indexing for Documents
    if (selectedType.value == 'Document') {
      loadingMessage.value = "UPLOADING DOCUMENT...";
      if (pickedFilePath.value == null) {
        Get.snackbar('Error', 'Please select a document first!');
        isLoading.value = false;
        return;
      }
      bool uploadSuccess = await _uploadDocument();
      if (!uploadSuccess) {
        isLoading.value = false;
        return;
      }
    } else if (selectedType.value == 'Link' || selectedType.value == 'Text') {
      loadingMessage.value = "STUDYING CONTENT...";
    }

    // Step 3: Trigger Generation API
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
      loadingMessage.value = "GENERATING QUESTIONS...";

      // Send all configuration preferences to the backend
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': selectedType.value == 'Topic'
              ? selectedTopic.value
              : (selectedType.value == 'Document'
                    ? pickedFileName.value
                    : input),
          'num_questions': numQuestions.value.toInt(),
          'difficulty': difficulty.value,
          'input_type': selectedType.value.toLowerCase(),
          'language': selectedLanguage.value,
          'exam_sector': selectedSector.value,
          'exam_name': selectedExam.value,
          'subject': selectedSubject.value,
        }),
      );

      // Step 4: Parse and Transition
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> questionList = data['questions'] ?? [];

        detectedSubject.value = data['detected_subject'];
        detectedTopic.value = data['detected_topic'];

        questions.assignAll(questionList);
        if (questionList.isNotEmpty) {
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

  /// Shows the high-end loading playground with cycling logos before starting questions.
  void _showPlaygroundTransition() async {
    isShowingPlayground.value = true;
    isQuizActive.value = false;
    currentLogoIndex.value = 0;

    // Cycle through gaming logos every 600ms
    _logoTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      currentLogoIndex.value = (currentLogoIndex.value + 1) % gameLogos.length;
    });

    await Future.delayed(const Duration(seconds: 3));

    _logoTimer?.cancel();
    isShowingPlayground.value = false;
    startQuiz(); // Auto-start the question timer and first question
  }

  /// Resets state and kicks off a fresh quiz attempt.
  void startQuiz() {
    isQuizActive.value = true;
    isQuizFinished.value = false;
    isReviewing.value = false;
    currentQuestionIndex.value = 0;
    score.value = 0;
    // Pre-fill answer list with nulls to track status per question
    userAnswers.assignAll(List.filled(questions.length, null));
    startTimer();
  }

  /// Dynamic timer duration based on the selected Exam Sector (Banking/UPSC need more/less time).
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

  /// Manages the per-question countdown.
  void startTimer() {
    _questionTimer?.cancel();
    remainingSeconds.value = _getTimerDuration();

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _questionTimer?.cancel();
        handleOptionSelected(-1); // Automatically skip/fail if time runs out
      }
    });
  }

  /// Called when a user clicks an option.
  void handleOptionSelected(int index) {
    _questionTimer?.cancel();
    userAnswers[currentQuestionIndex.value] = index;
    // userAnswers.refresh(); // Not strictly needed as we assign to index, but with RxList sometimes imperative updates need refresh? No, usually list[i]=x triggers update if using valid index or .assignAll.
    // Actually RxList modification by index might require .refresh() or creating new list. Let's use .refresh() or recreate list copy to be safe.
    userAnswers.refresh(); // Forces GetX UI update for list item changes

    // Subtle delay before auto-advancing to the next question for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      nextQuestion();
    });
  }

  /// Navigates to the next question or finishes the session.
  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      startTimer();
    } else {
      finishQuiz();
    }
  }

  /// Finalizes the result.
  void finishQuiz() {
    _calculateScore();
    isQuizActive.value = false;
    isQuizFinished.value = true;
    _saveResultToHistory();
  }

  /// Persists the session to SQLite for analytics
  Future<void> _saveResultToHistory() async {
    try {
      final result = QuizResult(
        topic: selectedType.value == 'Topic'
            ? selectedTopic.value
            : (detectedTopic.value ??
                  (selectedType.value == 'Document'
                      ? pickedFileName.value!
                      : 'Manual Text')),
        examName: selectedExam.value,
        subject: selectedType.value == 'Topic'
            ? selectedSubject.value
            : (detectedSubject.value ?? selectedSubject.value),
        score: score.value,
        totalQuestions: questions.length,
        date: DateTime.now(),
        quizDataJson: jsonEncode(questions),
      );
      await DatabaseService.instance.insertResult(result);

      // Refresh history if controller exists
      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().loadHistory();
      }
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Logic to count correct answers based on the LLM's 'answer' field and user selections.
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

  /// Restarts the same generated question set.
  void retryQuiz() {
    startQuiz();
  }

  /// Total reset to the home screen for a new topic.
  void startNewQuiz() {
    questions.clear();
    isQuizActive.value = false;
    isQuizFinished.value = false;
    errorMessage.value = null;
    isReviewing.value = false;
  }

  // UI state toggles for Review Mode
  void enterReviewMode() {
    isReviewing.value = true;
  }

  void exitReviewMode() {
    isReviewing.value = false;
  }

  /// Clears the selected document file.
  void removeFile() {
    pickedFileName.value = null;
    pickedFilePath.value = null;
  }

  /// Initiates a re-challenge for a specific weak subject
  void startReChallenge(String subject) {
    setSubject(subject);
    setType('Topic'); // Default to AI topic generation for re-challenge
    generateQuiz();
  }

  /// Initiates a re-challenge for a specific historical topic
  void startTopicReChallenge(String topic, String subject, String exam) {
    setType('Topic');
    selectedTopic.value = topic;
    setSubject(subject);
    setExam(exam);
    generateQuiz();
  }
}
