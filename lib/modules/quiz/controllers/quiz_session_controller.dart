import 'package:get/get.dart';
import 'package:test_project/models/quiz_question_model.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/progress/controllers/progress_controller.dart';
import 'package:test_project/services/quiz_api_service.dart';

class QuizSessionController extends GetxController {
  QuizSessionController(
    this._quizApiService,
    this._appStateController,
    this._progressController,
  );

  final QuizApiService _quizApiService;
  final AppStateController _appStateController;
  final ProgressController _progressController;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCompleted = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedOptionId = ''.obs;
  final RxString lastExplanation = ''.obs;
  final RxInt askedCount = 0.obs;
  final RxInt correctCount = 0.obs;
  final Rxn<QuizQuestionModel> currentQuestion = Rxn<QuizQuestionModel>();

  final int questionLimit = 10;

  double get progressFraction =>
      questionLimit == 0 ? 0 : askedCount.value / questionLimit;

  Future<void> startSession() async {
    askedCount.value = 0;
    correctCount.value = 0;
    selectedOptionId.value = '';
    errorMessage.value = '';
    lastExplanation.value = '';
    isCompleted.value = false;
    currentQuestion.value = null;
    await _loadNextQuestion();
  }

  Future<void> submitOption(String optionId) async {
    final activeQuestion = currentQuestion.value;
    if (activeQuestion == null || isSubmitting.value) {
      return;
    }

    isSubmitting.value = true;
    selectedOptionId.value = optionId;
    errorMessage.value = '';

    try {
      final result = await _quizApiService.submitAnswer(
        questionIndex: activeQuestion.questionIndex,
        selectedOptions: [optionId],
        examId: _appStateController.activeExamId,
        subjectId: _appStateController.selectedSubject.value,
        difficulty: _appStateController.selectedDifficulty.value,
      );

      askedCount.value++;
      if (result.correct) {
        correctCount.value++;
      }

      lastExplanation.value = result.explanation;
      _appStateController.incrementTodayAnswered();

      if (askedCount.value >= questionLimit) {
        await _completeSession();
        return;
      }

      await _loadNextQuestion();
    } catch (error) {
      errorMessage.value = _extractErrorMessage(error);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _loadNextQuestion() async {
    if (!_appStateController.hasSelectedPath) {
      errorMessage.value = 'Choose exam path first';
      return;
    }

    isLoading.value = true;
    selectedOptionId.value = '';

    try {
      final next = await _quizApiService.getNextQuestion(
        examId: _appStateController.activeExamId,
        subjectId: _appStateController.selectedSubject.value,
        difficulty: _appStateController.selectedDifficulty.value,
      );

      if (next == null) {
        await _completeSession();
        return;
      }

      currentQuestion.value = next;
    } catch (error) {
      errorMessage.value = _extractErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _completeSession() async {
    currentQuestion.value = null;
    isCompleted.value = true;
    await _progressController.fetchProgress();
  }

  String _extractErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException')) {
      return 'Cannot connect to backend. Start server at http://localhost:4000';
    }
    return 'Unable to continue quiz session';
  }
}
