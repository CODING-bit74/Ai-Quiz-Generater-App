import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/syllabus_model.dart';
import 'package:flutter/foundation.dart';

class SyllabusController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var syllabuses = <Syllabus>[].obs;
  var posts = <Post>[].obs;
  var organization = Rx<Organization?>(null);
  var userProgress = Rx<UserProgress?>(null);

  Future<void> fetchExamIntelligence(String examName) async {
    isLoading.value = true;
    try {
      // 1. Get Exam ID and Organization ID first
      final examRes = await _supabase
          .from('exams')
          .select('id, organization_id')
          .eq('exam_name', examName)
          .maybeSingle();

      if (examRes != null) {
        final examId = examRes['id'];
        final orgId = examRes['organization_id'];

        // 2. Fetch Syllabus
        final syllabusRes = await _supabase
            .from('syllabus')
            .select()
            .eq('exam_id', examId);

        syllabuses.assignAll(
          (syllabusRes as List).map((e) => Syllabus.fromJson(e)).toList(),
        );

        // 3. Fetch Posts
        final postsRes = await _supabase
            .from('posts')
            .select()
            .eq('exam_id', examId);

        posts.assignAll(
          (postsRes as List).map((e) => Post.fromJson(e)).toList(),
        );

        // 4. Fetch Organization
        if (orgId != null) {
          final orgRes = await _supabase
              .from('organizations')
              .select()
              .eq('id', orgId)
              .maybeSingle();
          if (orgRes != null) {
            organization.value = Organization.fromJson(orgRes);
          }
        }

        // 5. Fetch User Progress (Optional)
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final progressRes = await _supabase
              .from('user_progress')
              .select()
              .eq('user_id', userId)
              .eq('exam_id', examId)
              .maybeSingle();
          if (progressRes != null) {
            userProgress.value = UserProgress.fromJson(progressRes);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching intelligence: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
