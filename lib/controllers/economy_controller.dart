import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class EconomyController extends GetxController {
  // Global access
  static EconomyController get to => Get.find();

  // Observable state
  var credits = 100.obs;
  var isLoading = false.obs;
  var history = <Map<String, dynamic>>[].obs;
  var referralCode = "".obs; // Unique code for this user

  // Promo Codes
  final List<String> _redeemedCodes = [];
  final Map<String, int> _activePromoCodes = {
    "FREE50": 50,
    "STUDENTPOWR": 100,
    "GOVPREPAI": 75,
    "WELCOME": 25,
  };

  @override
  void onInit() {
    super.onInit();
    // 1. Initial Load
    refreshState();

    // 2. Listen for Auth Changes to refresh data for new users
    ever(AuthService.to.currentUser, (_) {
      debugPrint(
        "EconomyController: Auth state changed, refreshing credits...",
      );
      refreshState();
    });
  }

  /// Refreshes all economy-related state
  Future<void> refreshState() async {
    await loadCredits();
    await loadHistory();
    await checkDailyBonus();
  }

  /// Load transaction history
  Future<void> loadHistory() async {
    final data = await DatabaseService.instance.getCreditHistory();
    history.assignAll(data);
  }

  /// Load credits from local DB
  Future<void> loadCredits() async {
    isLoading.value = true;
    try {
      final dbCredits = await DatabaseService.instance.getCredits();
      credits.value = dbCredits;
      _generateReferralCode();
    } finally {
      isLoading.value = false;
    }
  }

  void _generateReferralCode() {
    final userId = AuthService.to.userId;
    if (userId != null && userId.length > 6) {
      // Create a unique-ish code from the UID
      referralCode.value = "GP-${userId.substring(0, 6).toUpperCase()}";
    } else {
      referralCode.value = "GP-GUEST";
    }
  }

  /// Check if user has enough credits
  bool hasEnoughCredits(int cost) {
    return credits.value >= cost;
  }

  /// Deduct credits for an action
  Future<bool> deductCredits(int cost) async {
    if (!hasEnoughCredits(cost)) {
      _showLowBalanceDialog();
      return false;
    }

    // Optimistic update
    credits.value -= cost;

    // Persist
    // Persist
    await DatabaseService.instance.updateCredits(credits.value);

    // Log Transaction
    await DatabaseService.instance.addCreditTransaction(
      -cost,
      "Mission",
      "Quiz Generation",
    );
    loadHistory(); // Refresh history

    return true;
  }

  /// Add credits (Bonus/Reward)
  Future<void> addCredits(
    int amount, {
    String type = "Reward",
    String description = "Bonus Credits",
  }) async {
    credits.value += amount;
    await DatabaseService.instance.updateCredits(credits.value);

    // Log Transaction
    await DatabaseService.instance.addCreditTransaction(
      amount,
      type,
      description,
    );
    loadHistory();

    Get.snackbar(
      "Credits Added!",
      "+$amount Credits received.",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Daily Login Bonus Logic
  Future<void> checkDailyBonus() async {
    final lastBonus = await DatabaseService.instance.getLastBonusDate();
    final now = DateTime.now();

    bool shouldGiveBonus = false;

    if (lastBonus == null) {
      shouldGiveBonus = true;
    } else {
      final lastDate = DateTime.parse(lastBonus);
      // Check if it's a different calendar day
      if (lastDate.year != now.year ||
          lastDate.month != now.month ||
          lastDate.day != now.day) {
        shouldGiveBonus = true;
      }
    }

    if (shouldGiveBonus) {
      // Give +20 credits
      credits.value += 20;
      await DatabaseService.instance.updateCredits(credits.value);
      await DatabaseService.instance.updateBonusDate(now.toIso8601String());

      // Log Transaction
      await DatabaseService.instance.addCreditTransaction(
        20,
        "Daily Bonus",
        "Login Reward",
      );
      loadHistory();

      // Show celebration dialog
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Dark slate
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text("Daily Bonus!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "You received +20 Credits for logging in today! 💎",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Awesome!"),
            ),
          ],
        ),
      );
    }
  }

  /// Verify and Redeem Promo Code
  Future<bool> verifyPromoCode(String code) async {
    final upperCode = code.toUpperCase().trim();

    if (_redeemedCodes.contains(upperCode)) {
      Get.snackbar(
        "Error",
        "You have already redeemed this code!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (_activePromoCodes.containsKey(upperCode)) {
      final amount = _activePromoCodes[upperCode]!;
      await addCredits(amount); // This handles DB and History logging

      _redeemedCodes.add(upperCode);

      Get.snackbar(
        "Success!",
        "Code redeemed! +$amount Credits",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } else {
      Get.snackbar(
        "Invalid Code",
        "This code does not exist or has expired.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Redeem a Referral Code
  Future<bool> redeemReferralCode(String code) async {
    final upperCode = code.toUpperCase().trim();

    if (upperCode == referralCode.value) {
      Get.snackbar(
        "Nice Try!",
        "You cannot redeem your own code.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // Check if it looks like a valid GP code
    if (upperCode.startsWith("GP-") && upperCode.length > 5) {
      // For this demo, we'll reward 100 credits for a referral
      await addCredits(
        100,
        type: "Referral",
        description: "Referred by $upperCode",
      );

      Get.snackbar(
        "Mission Successful!",
        "Referral intelligence verified. +100 Credits!",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return true;
    } else {
      Get.snackbar(
        "Invalid Intelligence",
        "This referral code is not recognized by HQ.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Simulate Watching Ad
  Future<void> watchAd() async {
    isLoading.value = true;

    // Simulate network delay / ad playing
    await Future.delayed(const Duration(seconds: 3));

    isLoading.value = false;

    await addCredits(10);
    Get.snackbar(
      "Ad Watched",
      "You earned +10 Credits!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Show "Out of Credits" Dialog
  void _showLowBalanceDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
            SizedBox(width: 12),
            Text("Low Balance", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "You don't have enough credits for this action.\nCome back tomorrow for your daily bonus!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}
