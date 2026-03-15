import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/history_model.dart';
import '../services/database_service.dart';
import 'history_controller.dart';
import '../data/loading_tips.dart';
import '../models/exam_management_models.dart'; // Import Models
import '../services/auth_service.dart';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class QuizController extends GetxController {
  // SERVICES
  final AudioPlayer _audioPlayer = AudioPlayer();
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
  // Tracks if the user has a finalized goal selected
  final RxBool isGoalSet = false.obs;
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

  // AI Tutor Persona Selection
  var selectedAgentPersona = 'Professor'.obs; // Default to Professor

  // Current educational tip shown during loading
  var currentTip = "".obs;

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

  // --- DATA MAPS (CORE CONFIGURATION) ---

  // Mapping of main exam sectors to their specific common exams
  // Mapping of main exam sectors to their specific common exams
  // NOW OBSERVABLE for dynamic updates
  var examSectors = <String, List<String>>{
    'Banking': ['IBPS PO', 'SBI PO', 'RBI Grade B', 'IBPS Clerk'],
    'SSC': ['SSC CGL', 'SSC CHSL', 'SSC MTS', 'SSC GD'],
    'UPSC': ['CSE (IAS)', 'CDS', 'CAPF', 'EPFO'],
    'Railway': ['RRB NTPC', 'RRB Group D', 'RRB ALP'],
    'Defence': ['AFCAT', 'NDA', 'Indian Army'],
    'Teaching': ['CTET', 'UGC NET', 'KVS'],
    'State PSC': ['UPPSC', 'BPSC', 'MPSC', 'RAS'],
    'Police': ['Delhi Police', 'UP Police', 'Bihar Police'],
  }.obs;

  // --- HELPER: GET DYNAMIC AVATAR PATH ---
  String get currentAvatarPath {
    String avatarPath = 'assets/images/human_avatar.png'; // Default

    // Normalize strings for comparison
    final s = selectedSector.value.toLowerCase();
    final e = selectedExam.value.toLowerCase();

    if (s.contains('bank')) {
      avatarPath = 'assets/images/human_avatar_banking.png';
    } else if (s.contains('ssc') || s.contains('railway')) {
      avatarPath = 'assets/images/human_avatar_ssc.png';
    } else if (s.contains('upsc') || s.contains('civil')) {
      avatarPath = 'assets/images/human_avatar_ias.png';
    } else if (s.contains('teach')) {
      avatarPath = 'assets/images/human_avatar_teaching.png';
    } else if (s.contains('medic')) {
      avatarPath = 'assets/images/human_avatar_medical.png';
    } else if (s.contains('law') || s.contains('judic')) {
      avatarPath = 'assets/images/human_avatar_judiciary.png';
    } else if (s.contains('defence')) {
      if (e.contains('navy')) {
        avatarPath = 'assets/images/human_avatar_navy.png';
      } else if (e.contains('police')) {
        avatarPath = 'assets/images/human_avatar_police.png';
      } else {
        avatarPath = 'assets/images/human_avatar_army.png';
      }
    } else if (s.contains('state')) {
      avatarPath = 'assets/images/human_avatar_civil_service.png';
    } else if (s.contains('police')) {
      avatarPath = 'assets/images/human_avatar_police.png';
    }

    return avatarPath;
  }

  // --- HELPER: GET DYNAMIC ROLE TITLE ---
  String get currentRoleTitle {
    String role = "ASPIRANT"; // Default

    final s = selectedSector.value.toLowerCase();
    final e = selectedExam.value.toLowerCase();

    if (s.contains('bank')) {
      role = "FUTURE BANKER";
    } else if (s.contains('ssc') || s.contains('railway')) {
      role = "GOVT. OFFICIAL";
    } else if (s.contains('upsc') || s.contains('civil')) {
      role = "FUTURE IAS";
    } else if (s.contains('teach')) {
      role = "FUTURE PROFESSOR";
    } else if (s.contains('medic')) {
      role = "FUTURE DOCTOR";
    } else if (s.contains('law') || s.contains('judic')) {
      role = "FUTURE JUDGE";
    } else if (s.contains('defence')) {
      if (e.contains('navy')) {
        role = "FUTURE ADMIRAL";
      } else if (e.contains('police')) {
        role = "FUTURE OFFICER";
      } else {
        role = "FUTURE WARRIOR";
      }
    } else if (s.contains('state')) {
      role = "FUTURE OFFICER";
    }

    return role;
  }

  // --- NEW STRUCTURED DATA FOR GOAL SELECTION ---
  var availableSectors = <ExamSector>[].obs;
  var availableExams = <Exam>[].obs;

  // Standard subjects available for all exam modes - NOW OBSERVABLE
  var availableSubjects = <String>[
    'Quant',
    'Reasoning',
    'English',
    'GA/GS',
  ].obs;

  // --- MAPPING: SECTOR -> SUBJECTS ---
  final Map<String, List<String>> sectorSubjects = {
    'Banking': ['Quant', 'Reasoning', 'English', 'GA/GS', 'Computer'],
    'SSC': ['Quant', 'Reasoning', 'English', 'GA/GS'],
    'Railway': ['Quant', 'Reasoning', 'GA/GS'],
    'UPSC': [
      'History',
      'Geography',
      'Polity',
      'Economy',
      'Science & Tech',
      'CSAT',
    ],
    'State PSC': ['History', 'Geography', 'Polity', 'Economy', 'State GK'],
    'Defence': ['Maths', 'G.A.', 'English', 'Reasoning'],
    'Teaching': [
      'Child Dev & Pedagogy',
      'Teaching Aptitude',
      'Language I',
      'Language II',
      'Maths',
      'EVS',
    ],
    'Medical': ['Biology', 'Physics', 'Chemistry'],
    'Engineering': ['Maths', 'Physics', 'Chemistry'],
    'Law': ['Legal Aptitude', 'Constitution', 'GK', 'English'],
    'Police': ['Reasoning', 'Numerical Ability', 'GK', 'Language'],
  };

  // Mapping of subjects to common high-yield topics
  // Mapping of subjects to common high-yield topics
  final Map<String, List<String>> subjectTopics = {
    // Banking/SSC/Common
    'Quant': [
      'Percentage',
      'Ratio',
      'Algebra',
      'Trigonometry',
      'Geometry',
      'Data Interpretation',
    ],
    'Reasoning': [
      'Puzzles',
      'Syllogism',
      'Blood Relations',
      'Coding-Decoding',
      'Analogy',
    ],
    'English': [
      'Reading Comp',
      'Cloze Test',
      'Para Jumbles',
      'Error Spotting',
      'Vocabulary',
    ],
    'GA/GS': [
      'Current Affairs',
      'History',
      'Polity',
      'Geography',
      'Science',
      'Static GK',
    ],
    'Computer': ['Hardware', 'Software', 'Networking', 'DBMS', 'Internet'],
    'Maths': ['Calculus', 'Vectors', 'Probability', 'Algebra', 'Trigonometry'],
    'Numerical Ability': [
      'Number System',
      'Simplification',
      'Percentage',
      'Average',
    ],

    // UPSC/State PSC
    'History': [
      'Ancient India',
      'Medieval India',
      'Modern India',
      'Art & Culture',
      'World History',
    ],
    'Geography': [
      'Physical Geography',
      'Indian Geography',
      'World Geography',
      'Environment',
    ],
    'Polity': [
      'Constitution',
      'Parliament',
      'Judiciary',
      'Panchayati Raj',
      'Rights',
    ],
    'Economy': [
      'Budget',
      'Banking',
      'National Income',
      'Schemes',
      'International Org',
    ],
    'Science & Tech': ['Space', 'Defence', 'Biotech', 'IT & Telecom'],
    'CSAT': [
      'Comprehension',
      'Reasoning',
      'Data Interpretation',
      'Basic Numeracy',
    ],
    'State GK': ['History', 'Geography', 'Culture', 'Economy', 'Districts'],

    // Defence
    'G.A.': [
      'Physics',
      'Chemistry',
      'Biology',
      'History',
      'Geography',
      'Current Events',
    ],

    // Teaching
    'Child Dev & Pedagogy': [
      'Growth & Dev',
      'Learning Theories',
      'Inclusive Edu',
      'Assessment',
    ],
    'Teaching Aptitude': ['Methods', 'Evaluation', 'Aids', 'Research'],
    'Language I': ['Grammar', 'Pedagogy', 'Comprehension'],
    'Language II': ['Grammar', 'Pedagogy', 'Comprehension'],
    'EVS': ['Family & Friends', 'Food & Shelter', 'Water', 'Travel'],

    // Science (Medical/Engg)
    'Biology': ['Zoology', 'Botany', 'Human Physiology', 'Genetics', 'Ecology'],
    'Physics': [
      'Mechanics',
      'Thermodynamics',
      'Optics',
      'Electromagnetism',
      'Modern Physics',
    ],
    'Chemistry': ['Organic', 'Inorganic', 'Physical', 'Biochemistry'],

    // Law
    'Legal Aptitude': ['Tort', 'Contracts', 'Criminal Law', 'Constitution'],
    'Constitution': [
      'Preamble',
      'Fundamental Rights',
      'Directive Principles',
      'Union & States',
    ],
    'GK': ['Static GK', 'Current Affairs', 'Legal Updates'],
    'Language': ['Hindi', 'English'],
  };

  final List<String> difficulties = ['Easy', 'Medium', 'Hard'];

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
  void onInit() {
    super.onInit();
    _fetchExamData();

    // Listen for Auth Changes to refresh user goal for new users
    ever(AuthService.to.currentUser, (_) {
      debugPrint("QuizController: Auth state changed, refreshing user goal...");
      _loadUserGoal();
    });

    // Listen to Sector selection to update subjects
    ever(selectedSector, (sector) {
      _updateSubjectsForSector(sector);
    });
  }

  @override
  void onClose() {
    // Cleanup timers and controllers to prevent memory leaks
    _questionTimer?.cancel();
    _logoTimer?.cancel();
    inputController.dispose();
    super.onClose();
  }

  /// Updates the available subjects list based on the selected sector
  void _updateSubjectsForSector(String sector) {
    // Find the closest key in our map
    String key = 'Banking'; // Default

    // Simple matching logic
    if (sector.toLowerCase().contains('bank')) {
      key = 'Banking';
    } else if (sector.toLowerCase().contains('ssc')) {
      key = 'SSC';
    } else if (sector.toLowerCase().contains('railway')) {
      key = 'Railway';
    } else if (sector.toLowerCase().contains('upsc') ||
        sector.toLowerCase().contains('civil')) {
      key = 'UPSC';
    } else if (sector.toLowerCase().contains('state')) {
      key = 'State PSC';
    } else if (sector.toLowerCase().contains('defence')) {
      key = 'Defence';
    } else if (sector.toLowerCase().contains('teach')) {
      key = 'Teaching';
    } else if (sector.toLowerCase().contains('medic') ||
        sector.toLowerCase().contains('neet')) {
      key = 'Medical';
    } else if (sector.toLowerCase().contains('engineer') ||
        sector.toLowerCase().contains('jee')) {
      key = 'Engineering';
    } else if (sector.toLowerCase().contains('law') ||
        sector.toLowerCase().contains('judic')) {
      key = 'Law';
    } else if (sector.toLowerCase().contains('police')) {
      key = 'Police';
    }

    // Update List
    if (sectorSubjects.containsKey(key)) {
      availableSubjects.value = sectorSubjects[key]!;
    } else {
      availableSubjects.value = ['Quant', 'Reasoning', 'English', 'GA/GS'];
    }

    // Reset Selection to first item
    if (availableSubjects.isNotEmpty) {
      setSubject(availableSubjects.first);
    }
  }

  /// Fetches Exam Sectors and Exams from Supabase
  Future<void> _fetchExamData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch Sectors
      final sectorsResponse = await supabase
          .from('sectors')
          .select()
          .order('name', ascending: true);

      final List<dynamic> localSectors = sectorsResponse as List;

      // 2. Fetch all exams (optimized: fetch all and group locally)
      final examsResponse = await supabase
          .from('exams')
          .select()
          .order('exam_name', ascending: true);

      final List<dynamic> localExams = examsResponse as List;

      // --- POPULATE STRUCTURED LISTS ---
      availableSectors.assignAll(
        localSectors.map((e) => ExamSector.fromMap(e)).toList(),
      );
      availableExams.assignAll(localExams.map((e) => Exam.fromMap(e)).toList());

      // 3. Build Map
      Map<String, List<String>> newMap = {};

      for (var sector in localSectors) {
        String sectorName = sector['name'];
        String sectorId = sector['id']; // UUID (String)

        List<String> examsInSector = localExams
            .where((e) => e['sector_id'] == sectorId)
            .map<String>((e) => e['exam_name'] as String)
            .toList();

        if (examsInSector.isNotEmpty) {
          newMap[sectorName] = examsInSector;
        } else {
          newMap[sectorName] = [];
        }
      }

      if (newMap.isNotEmpty) {
        examSectors.assignAll(newMap);

        // 4. Load User's Saved Goal
        await _loadUserGoal();

        // Reset selections if current invalid
        if (examSectors.isNotEmpty) {
          if (!examSectors.containsKey(selectedSector.value)) {
            selectedSector.value = examSectors.keys.first;
            final exams = examSectors[selectedSector.value];
            selectedExam.value = (exams != null && exams.isNotEmpty)
                ? exams.first
                : '';
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic exams: $e");
    }
  }

  /// Loads the user's saved goal from Supabase Profile
  Future<void> _loadUserGoal() async {
    try {
      final userId = AuthService.to.userId;
      if (userId == null) {
        isGoalSet.value = false;
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('target_exam_id')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['target_exam_id'] != null) {
        String examId = response['target_exam_id']; // UUID

        // Find the exam object
        try {
          if (availableExams.isEmpty || availableSectors.isEmpty) {
            isGoalSet.value = false;
            return;
          }
          final exam = availableExams.firstWhere((e) => e.id == examId);
          final sector = availableSectors.firstWhere(
            (s) => s.id == exam.sectorId,
          );

          selectedSector.value = sector.name;
          selectedExam.value = exam.name;
          isGoalSet.value = true;
          debugPrint("Loaded User Goal: ${sector.name} -> ${exam.name}");
        } catch (e) {
          isGoalSet.value = false;
          debugPrint("Saved exam/sector not found in current list.");
        }
      } else {
        isGoalSet.value = false;
      }
    } catch (e) {
      isGoalSet.value = false;
      debugPrint("Error loading user goal: $e");
    }
  }

  /// Saves the user's selected goal (Sector + Exam) to their profile
  Future<void> setUserGoal(Exam exam) async {
    try {
      final userId = AuthService.to.userId;
      if (userId == null) return;

      // 1. Update Supabase Profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'target_exam_id': exam.id, // UUID
            // 'selected_sector_id': exam.sectorId, // Removed as per new schema
          })
          .eq('id', userId);

      // 2. Update Local Controller State
      final sector = availableSectors.firstWhere(
        (s) => s.id == exam.sectorId,
        orElse: () =>
            ExamSector(id: 'unknown', name: selectedSector.value), // Fallback
      );

      selectedSector.value = sector.name;
      selectedExam.value = exam.name;
      isGoalSet.value = true;

      Get.snackbar(
        "Goal Updated",
        "Target set to ${exam.name}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint("Error saving user goal: $e");
      Get.snackbar("Error", "Failed to save goal.");
    }
  }

  // --- ACTIONS (UI CALLBACKS) ---

  // Updates the source type (Topic, Link, etc.)
  void setType(String type) => selectedType.value = type;

  // Updates sector and resets the exam selection to the first child of that sector
  void setSector(String sector) {
    selectedSector.value = sector;
    final exams = examSectors[sector];
    if (exams != null && exams.isNotEmpty) {
      selectedExam.value = exams.first;
    } else {
      selectedExam.value = '';
    }
  }

  // Simple setters for configuration state
  void setExam(String exam) => selectedExam.value = exam;
  void setSubject(String subject) {
    selectedSubject.value = subject;
    final topics = subjectTopics[subject];
    if (topics != null && topics.isNotEmpty) {
      selectedTopic.value = topics.first;
    } else {
      selectedTopic.value = '';
    }
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
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      } else if (Platform.isAndroid) {
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      } else {
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      }

      // Construct a Multipart request for file transmission
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_document'),
      );

      // Add Auth Header
      final token = AuthService.to.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

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
  Future<void> generateQuiz({
    String? topic,
    String? inputType,
    String? language,
    String? difficulty,
  }) async {
    final input = topic ?? inputController.text.trim();
    final type = inputType ?? selectedType.value;
    final lang = language ?? selectedLanguage.value;
    final diff = difficulty ?? this.difficulty.value;

    // Ensure state reflects the input type so UI reacts appropriately
    if (inputType != null) {
      selectedType.value = inputType;
    }

    // Step 1: Validation
    if (type != 'Topic' && type != 'Document' && input.isEmpty) {
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
    if (type == 'Document') {
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
    } else if (type == 'Link' || type == 'link') {
      loadingMessage.value = "STUDYING CONTENT...";
    } else if (type == 'PYQ Search' || type == 'pyq_search') {
      loadingMessage.value = "SEARCHING PYQ DATABASE...";
    }

    // Start AI Status Message Rotation and Logo Animation
    _simulateAIProcessing();
    _startLogoAnimation();

    // Step 3: Trigger Generation API
    try {
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      } else if (Platform.isAndroid) {
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      } else {
        baseUrl = 'https://ai-quiz-generater-app.onrender.com';
      }

      final url = Uri.parse('$baseUrl/generate_quiz');
      loadingMessage.value = "GENERATING QUESTIONS...";

      // Send all configuration preferences to the backend
      final token = AuthService.to.accessToken;
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'topic': type == 'Topic'
              ? selectedTopic.value
              : (type == 'Document' ? pickedFileName.value : input),
          'num_questions': numQuestions.value.toInt(),
          'difficulty': diff,
          'input_type': type == 'PYQ Search'
              ? 'pyq_search'
              : type.toLowerCase(),
          'language': lang,
          'exam_sector': selectedSector.value,
          'exam_name': selectedExam.value,
          'subject': selectedSubject.value,
          'agent_style': selectedAgentPersona.value,
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
        try {
          final errorData = jsonDecode(response.body);
          errorMessage.value =
              errorData['error'] ?? 'Error: ${response.statusCode}';
        } catch (e) {
          errorMessage.value =
              'Failed: ${response.statusCode}\n${response.body}';
        }
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Starts the cycling logo animation
  void _startLogoAnimation() {
    _logoTimer?.cancel();
    currentLogoIndex.value = 0;
    _logoTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      currentLogoIndex.value = (currentLogoIndex.value + 1) % gameLogos.length;
    });
  }

  /// Shows the high-end loading playground with cycling logos before starting questions.
  void _showPlaygroundTransition() async {
    isShowingPlayground.value = true;
    isQuizActive.value = false;
    // Don't reset logo index here if it's already running from loading phase
    if (_logoTimer == null || !_logoTimer!.isActive) {
      _startLogoAnimation();
    }

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
    _isTransitioning = false;
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

  // --- SOUND EFFECTS ---
  // --- SOUND EFFECTS ---
  Future<void> _playSound() async {
    try {
      // Use a single, smooth click sound for all interactions
      const String soundPath =
          'audio/universfield-system-notification-199277.mp3';
      await _audioPlayer.stop(); // Stop any previous sound
      await _audioPlayer.play(AssetSource(soundPath), volume: 0.5);
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  bool _isTransitioning = false;

  /// Called when a user clicks an option.
  void handleOptionSelected(int index) {
    if (!isQuizActive.value || _isTransitioning) return;

    _questionTimer?.cancel();
    _isTransitioning = true;

    // 1. Record Answer
    if (currentQuestionIndex.value < userAnswers.length) {
      userAnswers[currentQuestionIndex.value] = index;
      userAnswers.refresh(); // Forces GetX UI update
    }

    // 2. Play Sound (Independent of correctness)
    _playSound();

    // 3. Advance
    // Subtle delay before auto-advancing to the next question for better UX
    Future.delayed(const Duration(milliseconds: 800), () {
      _isTransitioning = false;
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
        id: "MIS-${DateTime.now().millisecondsSinceEpoch}",
        userId: Get.find<AuthService>().userId,
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

      // Update User Progress in Supabase
      await DatabaseService.instance.updateExamProgress(selectedExam.value, 1);

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
        final options =
            (question['options'] as List<dynamic>?) ?? ['A', 'B', 'C', 'D'];
        final selectedOption = options[userAnswerIndex];
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

  // --- ANIMATION LOGIC ---

  // List of icons rendered during the playground loading transition
  // Now dynamic based on the quiz type!
  List<IconData> get gameLogos {
    if (selectedType.value == 'Link' || selectedType.value == 'link') {
      return [
        Icons.play_circle_fill,
        Icons.video_library_rounded,
        Icons.subtitles,
        Icons.analytics_outlined,
        Icons.ondemand_video_rounded,
      ];
    } else if (selectedType.value == 'Document') {
      return [
        Icons.description_rounded,
        Icons.picture_as_pdf_rounded,
        Icons.upload_file_rounded,
        Icons.folder_open_rounded,
        Icons.find_in_page_rounded,
      ];
    } else if (selectedType.value == 'Text') {
      return [
        Icons.text_snippet_rounded,
        Icons.article_rounded,
        Icons.edit_note_rounded,
        Icons.menu_book_rounded,
        Icons.segment_rounded,
      ];
    }
    // Topic / Default
    return [
      Icons.psychology_rounded,
      Icons.auto_awesome,
      Icons.school_rounded,
      Icons.lightbulb_rounded,
      Icons.trending_up_rounded,
    ];
  }

  // ... (existing timer logic) ...

  /// Cycles through "AI Thinking" messages to keep the user engaged during loading
  void _simulateAIProcessing() async {
    List<String> steps;
    String type = selectedType.value.toLowerCase();

    if (type == 'link') {
      steps = [
        "FETCHING VIDEO TRANSCRIPT...",
        "ANALYZING AUDIO PATTERNS...",
        "EXTRACTING KEY CONCEPTS...",
        "GENERATING RELEVANT QUESTIONS...",
        "VERIFYING FACTS...",
        "READY FOR PLAYBACK...",
      ];
    } else if (type == 'document') {
      steps = [
        "READING DOCUMENT FILE...",
        "PARSING TEXT STRUCTURE...",
        "IDENTIFYING KEY CHAPTERS...",
        "EXTRACTING QUIZ CONTENT...",
        "FORMATTING QUESTIONS...",
        "FINALIZING DOCUMENT QUIZ...",
      ];
    } else if (type == 'text') {
      steps = [
        "PROCESSING TEXT INPUT...",
        "ANALYZING CONTEXT...",
        "DETECTING THEMES...",
        "STRUCTURING QUESTIONS...",
        "VALIDATING ANSWERS...",
        "PREPARING QUIZ...",
      ];
    } else {
      // Topic
      steps = [
        "MAPPING KNOWLEDGE GRAPH...",
        "SCANNING EXAM PATTERNS...",
        "CALIBRATING DIFFICULTY...",
        "DRAFTING QUESTIONS...",
        "VERIFYING ANSWERS...",
        "OPTIMIZING FOR YOU...",
      ];
    }

    for (var step in steps) {
      if (!isLoading.value) break;
      loadingMessage.value = step;
      // Update tip with a random one occasionally
      if (Random().nextBool()) {
        currentTip.value =
            educationalTips[Random().nextInt(educationalTips.length)];
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }
}
