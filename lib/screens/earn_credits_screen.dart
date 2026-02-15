import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/economy_controller.dart';

class EarnCreditsScreen extends StatelessWidget {
  const EarnCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EconomyController economyController = Get.find<EconomyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF1F5F9), Colors.white],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildEarnCard(
                        context,
                        "Watch Transmission",
                        "View a brief intelligence briefing to earn 5 credits",
                        Icons.play_circle_fill_rounded,
                        Colors.blue,
                        () => _handleWatchAd(economyController),
                      ),
                      const SizedBox(height: 20),
                      _buildEarnCard(
                        context,
                        "Daily Check-in",
                        "Access the HQ daily for a 2 credit bonus",
                        Icons.calendar_today_rounded,
                        Colors.orange,
                        null, // Automatic in controller usually
                        isLocked: true,
                      ),
                      const SizedBox(height: 20),
                      _buildEarnCard(
                        context,
                        "Promo Code",
                        "Enter a secret command code for massive rewards",
                        Icons.vpn_key_rounded,
                        Colors.purple,
                        () => _showPromoDialog(context, economyController),
                      ),
                      const SizedBox(height: 20),
                      _buildEarnCard(
                        context,
                        "Refer & Earn",
                        "Invite fellow agents to the HQ and earn 100 credits",
                        Icons.handshake_rounded,
                        Colors.teal,
                        () => _showReferralDialog(context, economyController),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              foregroundColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "EARN TOKENS",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Refuel your intelligence credits for more simulations",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isLocked = false,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : color.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                  color: isLocked ? Colors.grey : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleWatchAd(EconomyController controller) {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emergency_recording_rounded,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                "TRANSMISSION COMPLETE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Credits successfully intel-linked to your account.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.addCredits(
                      5,
                      description: "Intelligence Briefing Reward",
                    );
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("RECEIVE TOKENS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromoDialog(BuildContext context, EconomyController controller) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "ENTER SECRET CODE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "COMMAND_ALPHA",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final code = textController.text.trim();
              if (code.isEmpty) return;

              final success = await controller.verifyPromoCode(code);
              if (success) {
                Get.back();
              }
            },
            child: const Text("EXECUTE"),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog(BuildContext context, EconomyController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.teal.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 64),
              const SizedBox(height: 24),
              const Text(
                "REFER A WINGMAN",
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Share your unique signal code. When they join the mission, you both receive 100 extra credits.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Obx(
                        () => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            controller.referralCode.value,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: controller.referralCode.value),
                        );
                        Get.snackbar(
                          "Signal Copied",
                          "Code copied to clipboard.",
                          backgroundColor: Colors.teal,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final message =
                        "Join me on GovPrpeAi! Use my code ${controller.referralCode.value} to get 100 bonus credits and start your exam prep journey! 🚀";
                    Clipboard.setData(ClipboardData(text: message));
                    Get.snackbar(
                      "Ready to Share",
                      "Invite message copied to clipboard.",
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text("SHARE MISSION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showRedeemReferralDialog(context, controller),
                child: const Text(
                  "Have a Referral Code? Redeem Now",
                  style: TextStyle(color: Colors.teal, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemReferralDialog(
    BuildContext context,
    EconomyController controller,
  ) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "REDEEM REFERRAL",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "GP-XXXXXX",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.teal),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final code = textController.text.trim();
              if (code.isEmpty) return;

              final success = await controller.redeemReferralCode(code);
              if (success) {
                Get.back(); // Close dialog
                Get.back(); // Close main referral dialog
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }
}
