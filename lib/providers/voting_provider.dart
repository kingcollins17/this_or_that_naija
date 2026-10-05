import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/comment_model.dart';
import '../repositories/voting_repository.dart';

final votingRepositoryProvider = Provider<VotingRepository>((ref) {
  return VotingRepository();
});

final questionsStreamProvider = StreamProvider<List<QuestionModel>>((ref) {
  return ref.watch(votingRepositoryProvider).streamQuestions();
});

final commentsStreamProvider = StreamProvider.family<List<CommentModel>, String>((ref, questionId) {
  return ref.watch(votingRepositoryProvider).streamComments(questionId);
});

class CardSessionState {
  final Map<String, String> sessionVotes; // questionId -> option
  const CardSessionState({this.sessionVotes = const {}});

  CardSessionState copyWith({Map<String, String>? sessionVotes}) {
    return CardSessionState(sessionVotes: sessionVotes ?? this.sessionVotes);
  }
}

class CardSessionNotifier extends StateNotifier<CardSessionState> {
  final VotingRepository _repo;

  CardSessionNotifier(this._repo) : super(const CardSessionState());

  Future<void> castVote(String questionId, String option) async {
    state = state.copyWith(
      sessionVotes: {...state.sessionVotes, questionId: option},
    );
    await _repo.submitVote(questionId: questionId, option: option);
  }
}

final cardSessionProvider = StateNotifierProvider<CardSessionNotifier, CardSessionState>((ref) {
  return CardSessionNotifier(ref.watch(votingRepositoryProvider));
});
