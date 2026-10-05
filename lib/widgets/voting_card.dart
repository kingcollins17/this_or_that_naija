import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/question_model.dart';
import 'choice_panel.dart';
import 'comments_sheet.dart';

class VotingCard extends StatelessWidget {
  final QuestionModel question;
  final String? userVote;
  final bool hasVoted;
  final VoidCallback onSelectA;
  final VoidCallback onSelectB;
  final VoidCallback onShare;

  const VotingCard({
    super.key,
    required this.question,
    required this.userVote,
    required this.hasVoted,
    required this.onSelectA,
    required this.onSelectB,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(
                child: ChoicePanel(
                  text: question.optionA.text,
                  banter: question.optionA.banter,
                  percentage: question.percentA,
                  isSelected: userVote == 'A',
                  hasVoted: hasVoted,
                  baseColor: const Color(0xFF007A3D),
                  onTap: hasVoted ? null : onSelectA,
                ),
              ),
              Expanded(
                child: ChoicePanel(
                  text: question.optionB.text,
                  banter: question.optionB.banter,
                  percentage: question.percentB,
                  isSelected: userVote == 'B',
                  hasVoted: hasVoted,
                  baseColor: const Color(0xFFC62828),
                  onTap: hasVoted ? null : onSelectB,
                ),
              ),
            ],
          ),
          if (!hasVoted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
              ),
              child: const Text(
                'VS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsSheet(
                        question: question,
                        userVote: userVote ?? 'A',
                      ),
                    );
                  },
                  icon: const Icon(Icons.mode_comment_outlined, size: 16),
                  label: const Text('Banter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    elevation: 6,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ).animate().scale(curve: Curves.elasticOut, duration: 400.ms),
        ],
      ),
    );
  }
}
