import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DuelTab extends StatelessWidget {
  const DuelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge Friends',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C2740),
                ),
              ),
              Text(
                'Compete in MCQ battles',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF65728A),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              _statsPanel(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      title: 'Create Duel',
                      subtitle: 'Start a challenge',
                      icon: Icons.add,
                      color: const Color(0xFF1D67DA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      title: 'Join Duel',
                      subtitle: 'Enter code',
                      icon: Icons.share_outlined,
                      color: const Color(0xFF22A065),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Your Duels',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: const Color(0xFF213252),
                ),
              ),
              const SizedBox(height: 10),
              _duelCard(
                name: 'Rahul Kumar',
                topic: 'Mathematics . 10 Qs',
                userScore: 8,
                opponentScore: 6,
                isLive: false,
              ),
              _duelCard(
                name: 'Priya Singh',
                topic: 'Science . 10 Qs',
                userScore: 5,
                opponentScore: 7,
                isLive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A3FD1), Color(0xFF5737C7)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(title: 'Wins', value: '12', icon: Icons.emoji_events_outlined),
          _StatItem(title: 'Streak', value: '5', icon: Icons.local_fire_department_outlined),
          _StatItem(title: 'Duels', value: '28', icon: Icons.groups_outlined),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _duelCard({
    required String name,
    required String topic,
    required int userScore,
    required int opponentScore,
    required bool isLive,
  }) {
    final maxScore = (userScore > opponentScore ? userScore : opponentScore).toDouble();
    final safeMax = maxScore == 0 ? 1 : maxScore;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFC23692),
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1D2A45)),
                    ),
                    Text(
                      topic,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6C7991)),
                    ),
                  ],
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1D1FA164),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Live',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1B915B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: userScore / safeMax,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF2972E7),
                  backgroundColor: const Color(0xFFE1E9F8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$userScore VS $opponentScore',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3A55),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: opponentScore / safeMax,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFC83FB2),
                  backgroundColor: const Color(0xFFE1E9F8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD989), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }
}
