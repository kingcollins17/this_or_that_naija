import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';
import '../models/comment_model.dart';
import '../services/local_storage_service.dart';

class VotingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  VotingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<UserCredential?> ensureAnonymousAuth() async {
    if (_auth.currentUser != null) {
      return null;
    }
    return await _auth.signInAnonymously();
  }

  Stream<List<QuestionModel>> streamQuestions() {
    return _firestore
        .collection('questions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> submitVote({
    required String questionId,
    required String option, // 'A' or 'B'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");
    if (LocalStorageService.hasVoted(questionId)) return;

    final batch = _firestore.batch();
    final questionDocRef = _firestore.collection('questions').doc(questionId);
    final userVoteDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('votes')
        .doc(questionId);

    final fieldToIncrement = option == 'A' ? 'countA' : 'countB';

    batch.update(questionDocRef, {
      fieldToIncrement: FieldValue.increment(1),
      'totalVotes': FieldValue.increment(1),
    });

    batch.set(userVoteDocRef, {
      'choice': option,
      'votedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await LocalStorageService.saveVote(questionId, option);
  }

  Stream<List<CommentModel>> streamComments(String questionId) {
    return _firestore
        .collection('questions')
        .doc(questionId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> postComment({
    required String questionId,
    required String text,
    required String selectedOption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    final displayName = LocalStorageService.getUserDisplayName();

    await _firestore
        .collection('questions')
        .doc(questionId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': displayName,
      'selectedOption': selectedOption,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitSuggestion({
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    await _firestore.collection('submissions').add({
      'userId': user.uid,
      'optionA': optionA,
      'optionB': optionB,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
