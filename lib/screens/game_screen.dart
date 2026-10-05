import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:confetti/confetti.dart';
import '../providers/voting_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/share_helper.dart';
import '../widgets/voting_card.dart';
import 'suggest_question_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final CardSwiperController _cardController = CardSwiperController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsStreamProvider);
    final cardSession = ref.watch(cardSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text(
          'THIS OR THAT NAIJA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.greenAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuggestQuestionScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return const Center(child: Text("No active dilemmas available.", style: TextStyle(color: Colors.white60)));
              }

              return CardSwiper(
                controller: _cardController,
                cardsCount: questions.length,
                numberOfCardsDisplayed: min(3, questions.length),
                backCardOffset: const Offset(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                onSwipe: (prevIdx, currIdx, direction) {
                  final question = questions[prevIdx];
                  final option = direction == CardSwiperDirection.left ? 'A' : 'B';
                  if (!LocalStorageService.hasVoted(question.id)) {
                    ref.read(cardSessionProvider.notifier).castVote(question.id, option);
                    _confettiController.play();
                  }
                  return true;
                },
                cardBuilder: (context, index, percentX, percentY) {
                  final question = questions[index];
                  final localChoice = LocalStorageService.getVoteChoice(question.id);
                  final sessionChoice = cardSession.sessionVotes[question.id];
                  final effectiveChoice = sessionChoice ?? localChoice;
                  final hasVoted = effectiveChoice != null;

                  return VotingCard(
                    question: question,
                    userVote: effectiveChoice,
                    hasVoted: hasVoted,
                    onSelectA: () => _cardController.swipe(CardSwiperDirection.left),
                    onSelectB: () => _cardController.swipe(CardSwiperDirection.right),
                    onShare: () => ShareHelper.shareDilemma(
                      context: context,
                      question: question,
                      selectedOption: effectiveChoice ?? 'A',
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Color(0xFF007A3D), Colors.white, Colors.amberAccent],
          ),
        ],
      ),
    );
  }
}
