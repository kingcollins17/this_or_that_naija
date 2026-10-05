Here is the comprehensive, end-to-end Product Development Plan for **This or That Naija**. It covers strategy, technical architecture, complete codebase organization, offline resilience, testing, and production deployment without omitting any phase.

---

## 1. Product Strategy & Technical Specifications

* **App Name:** This or That Naija
* **Target Audience:** Young Nigerians (16–35) seeking low-friction, culturally relatable entertainment.
* **Core Value Proposition:** High-speed cultural debate with immediate peer validation, shareable status cards, and uncensored banter.
* **Architecture Pattern:** Serverless Client-First architecture using Flutter, Firebase Cloud Firestore, Firebase Anonymous Authentication, and Hive for persistent zero-latency local caching.

```
+-----------------------------------------------------------+
|                       Flutter Client                      |
|                                                           |
|   +-------------------+          +--------------------+   |
|   | UI & Swiper Deck  |<-------->| Riverpod State     |   |
|   +-------------------+          +---------+----------+   |
|             |                              |              |
|             v                              v              |
|   +-------------------+          +--------------------+   |
|   | Hive (Local Cache)|          | Voting Repository  |   |
|   +-------------------+          +---------+----------+   |
+--------------------------------------------|--------------+
                                             |
                                    HTTPS / Firestore SDK
                                             |
                                             v
                      +-------------------------------------+
                      |           Firebase Backend          |
                      |                                     |
                      |   +-----------------------------+   |
                      |   | Anonymous Auth Engine       |   |
                      |   +-----------------------------+   |
                      |   | Firestore Collections:      |   |
                      |   |  - /questions/{id}          |   |
                      |   |  - /questions/{id}/comments |   |
                      |   |  - /users/{id}/votes        |   |
                      |   +-----------------------------+   |
                      +-------------------------------------+

```

---

## 2. Directory Structure

```text
this_or_that_naija/
├── android/
├── ios/
├── assets/
│   ├── fonts/
│   ├── images/
│   └── seed_questions.json
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart
    │   │   └── app_strings.dart
    │   ├── theme/
    │   │   └── app_theme.dart
    │   └── utils/
    │       ├── error_handler.dart
    │       └── share_helper.dart
    ├── models/
    │   ├── question_model.dart
    │   └── comment_model.dart
    ├── services/
    │   ├── local_storage_service.dart
    │   └── firebase_service.dart
    ├── repositories/
    │   └── voting_repository.dart
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── questions_provider.dart
    │   ├── voting_provider.dart
    │   └── comments_provider.dart
    ├── widgets/
    │   ├── voting_card.dart
    │   ├── choice_panel.dart
    │   ├── comments_sheet.dart
    │   ├── share_modal_card.dart
    │   └── stats_progress_bar.dart
    └── screens/
        ├── splash_screen.dart
        ├── game_screen.dart
        └── suggest_question_screen.dart

```

---

## 3. Configuration & Dependency Manifest

### `pubspec.yaml`

```yaml
name: this_or_that_naija
description: Fast-paced Nigerian micro-polling & cultural banter game.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Firebase Suite
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4

  # State Management
  flutter_riverpod: ^2.6.1

  # Local Key-Value Persistence
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Interaction, Card Deck & Animations
  flutter_card_swiper: ^7.0.0
  flutter_animate: ^4.5.0
  confetti: ^0.7.0

  # Image Export & Social Sharing
  screenshot: ^3.0.0
  share_plus: ^10.1.1
  path_provider: ^2.1.4

  # Styling & Helpers
  google_fonts: ^6.2.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/seed_questions.json

```

---

## 4. Firestore Database Architecture & Security Rules

### Security Rules (`firestore.rules`)

Enforces atomic counter increments, authenticated submissions, and comment character limits without a dedicated backend server.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Questions collection
    match /questions/{questionId} {
      allow read: if true;
      
      // Only allow increments of countA, countB, and totalVotes by exactly 1
      allow update: if request.auth != null &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['countA', 'countB', 'totalVotes']) &&
        (
          (request.resource.data.countA == resource.data.countA + 1 && request.resource.data.totalVotes == resource.data.totalVotes + 1) ||
          (request.resource.data.countB == resource.data.countB + 1 && request.resource.data.totalVotes == resource.data.totalVotes + 1)
        );
      allow create, delete: if false;

      // Nested Comments Subcollection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null &&
          request.resource.data.userId == request.auth.uid &&
          request.resource.data.selectedOption in ['A', 'B'] &&
          request.resource.data.text is string &&
          request.resource.data.text.trim().size() > 0 &&
          request.resource.data.text.size() <= 280;
        allow update, delete: if false;
      }
    }

    // User Voting History
    match /users/{userId}/votes/{questionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // User Suggestions
    match /submissions/{submissionId} {
      allow create: if request.auth != null &&
        request.resource.data.keys().hasAll(['optionA', 'optionB', 'category', 'userId']) &&
        request.resource.data.userId == request.auth.uid;
      allow read, update, delete: if false;
    }
  }
}

```

### Composite Indexes (`firestore.indexes.json`)

```json
{
  "indexes": [
    {
      "collectionGroup": "comments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "totalVotes", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}

```

---

## 5. Core Data Models

### `lib/models/question_model.dart`

```dart
class OptionData {
  final String text;
  final String banter;

  const OptionData({required this.text, required this.banter});

  factory OptionData.fromMap(Map<String, dynamic> map) {
    return OptionData(
      text: map['text'] as String? ?? '',
      banter: map['banter'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'text': text, 'banter': banter};
}

class QuestionModel {
  final String id;
  final String category;
  final OptionData optionA;
  final OptionData optionB;
  final int countA;
  final int countB;
  final int totalVotes;
  final bool isActive;

  const QuestionModel({
    required this.id,
    required this.category,
    required this.optionA,
    required this.optionB,
    required this.countA,
    required this.countB,
    required this.totalVotes,
    this.isActive = true,
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return QuestionModel(
      id: docId,
      category: data['category'] as String? ?? 'general',
      optionA: OptionData.fromMap(Map<String, dynamic>.from(data['optionA'] ?? {})),
      optionB: OptionData.fromMap(Map<String, dynamic>.from(data['optionB'] ?? {})),
      countA: (data['countA'] as num?)?.toInt() ?? 0,
      countB: (data['countB'] as num?)?.toInt() ?? 0,
      totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  double get percentA => totalVotes == 0 ? 50.0 : (countA / totalVotes) * 100;
  double get percentB => totalVotes == 0 ? 50.0 : (countB / totalVotes) * 100;
}

```

### `lib/models/comment_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String selectedOption;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.selectedOption,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CommentModel(
      id: docId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Naija Citizen',
      selectedOption: data['selectedOption'] as String? ?? 'A',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'selectedOption': selectedOption,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

```

---

## 6. Services & Repositories

### `lib/services/local_storage_service.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _votedBoxName = 'user_votes_box';
  static const String _settingsBoxName = 'app_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_votedBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Box<String> get _votedBox => Hive.box<String>(_votedBoxName);
  static Box get _settingsBox => Hive.box(_settingsBoxName);

  static bool hasVoted(String questionId) => _votedBox.containsKey(questionId);

  static String? getVoteChoice(String questionId) => _votedBox.get(questionId);

  static Future<void> saveVote(String questionId, String option) async {
    await _votedBox.put(questionId, option);
  }

  static String getUserDisplayName() {
    return _settingsBox.get('display_name', defaultValue: 'Naija Citizen');
  }

  static Future<void> setUserDisplayName(String name) async {
    await _settingsBox.put('display_name', name);
  }
}

```

### `lib/repositories/voting_repository.dart`

```dart
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

  Future<UserCredential> ensureAnonymousAuth() async {
    if (_auth.currentUser != null) {
      return _auth.getRedirectResult().then((_) => throw Exception()).catchError((_) {
        return _auth.signInAnonymously();
      });
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
}

```

---

## 7. Riverpod State Providers

### `lib/providers/voting_provider.dart`

```dart
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

```

---

## 8. Presentation Layer Components

### `lib/widgets/choice_panel.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChoicePanel extends StatelessWidget {
  final String text;
  final String banter;
  final double percentage;
  final bool isSelected;
  final bool hasVoted;
  final Color baseColor;
  final VoidCallback? onTap;

  const ChoicePanel({
    super.key,
    required this.text,
    required this.banter,
    required this.percentage,
    required this.isSelected,
    required this.hasVoted,
    required this.baseColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Stack(
          children: [
            Container(color: baseColor),
            if (hasVoted)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (hasVoted) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
                      const SizedBox(height: 8),
                      Text(
                        banter,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ],
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 16,
                right: 16,
                child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
              ),
          ],
        ),
      ),
    );
  }
}

```

### `lib/widgets/voting_card.dart`

```dart
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

```

### `lib/widgets/comments_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/question_model.dart';
import '../providers/voting_provider.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final QuestionModel question;
  final String userVote;

  const CommentsSheet({
    super.key,
    required this.question,
    required this.userVote,
  });

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(votingRepositoryProvider).postComment(
            questionId: widget.question.id,
            text: content,
            selectedOption: widget.userVote,
          );
      _textController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(widget.question.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Community Banter',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Drop your hot take!', style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = comments[index];
                    final isA = item.selectedOption == 'A';
                    final badgeLabel = isA ? widget.question.optionA.text : widget.question.optionB.text;
                    final badgeColor = isA ? const Color(0xFF007A3D) : const Color(0xFFC62828);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.userName,
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: badgeColor, width: 0.8),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('hh:mm a').format(item.createdAt),
                            style: const TextStyle(color: Colors.white24, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161616),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Defend your choice...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.greenAccent),
                          onPressed: _handlePost,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```

### `lib/utils/share_helper.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/question_model.dart';

class ShareHelper {
  static final ScreenshotController _screenshotController = ScreenshotController();

  static Future<void> shareDilemma({
    required BuildContext context,
    required QuestionModel question,
    required String selectedOption,
  }) async {
    final imageBytes = await _screenshotController.captureFromWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: 360,
          height: 480,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'THIS OR THAT NAIJA',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
              ),
              const Spacer(),
              _buildShareChoiceRow(question.optionA.text, question.percentA, selectedOption == 'A'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              _buildShareChoiceRow(question.optionB.text, question.percentB, selectedOption == 'B'),
              const Spacer(),
              const Text('Where you stand? Tap to play.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/share_${question.id}.png').create();
    await imagePath.writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(imagePath.path)],
      text: 'Which side you dey? I picked ${selectedOption == 'A' ? question.optionA.text : question.optionB.text}!',
    );
  }

  static Widget _buildShareChoiceRow(String label, double percent, bool isUserPick) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUserPick ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUserPick ? Colors.greenAccent : Colors.transparent, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

```

### `lib/screens/game_screen.dart`

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:confetti/confetti.dart';
import '../models/question_model.dart';
import '../providers/voting_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/share_helper.dart';
import '../widgets/voting_card.dart';

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

```

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/local_storage_service.dart';
import 'repositories/voting_repository.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalStorageService.init();

  final container = ProviderContainer();
  try {
    await container.read(votingRepositoryProvider).ensureAnonymousAuth();
  } catch (e) {
    debugPrint("Failed to perform auto anonymous sign in: $e");
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ThisOrThatApp(),
    ),
  );
}

class ThisOrThatApp extends StatelessWidget {
  const ThisOrThatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'This or That Naija',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007A3D),
          secondary: Colors.greenAccent,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

```

---

## 9. Content Seed Data (`assets/seed_questions.json`)

To prefill Firestore via a Node.js or Dart administrative script, use this set:

```json
[
  {
    "id": "chow_001",
    "category": "chow",
    "isActive": true,
    "optionA": { "text": "Party Jollof", "banter": "Bottom pot or nothing" },
    "optionB": { "text": "Fried Rice", "banter": "Soft life committee" },
    "countA": 1820,
    "countB": 940,
    "totalVotes": 2760
  },
  {
    "id": "street_002",
    "category": "street",
    "isActive": true,
    "optionA": { "text": "Danfo", "banter": "Conductor shouting enter with your change" },
    "optionB": { "text": "Keke Napep", "banter": "Wind hitting your face in traffic" },
    "countA": 890,
    "countB": 1450,
    "totalVotes": 2340
  },
  {
    "id": "lifestyle_003",
    "category": "lifestyle",
    "isActive": true,
    "optionA": { "text": "Lekki Toll Gate Queue", "banter": "Card declined at the booth" },
    "optionB": { "text": "Third Mainland Traffic", "banter": "Sleeping from 6 AM till 8 AM" },
    "countA": 420,
    "countB": 1980,
    "totalVotes": 2400
  },
  {
    "id": "campus_004",
    "category": "campus",
    "isActive": true,
    "optionA": { "text": "Night Class Reading", "banter": "Mosquitoes keeping you awake" },
    "optionB": { "text": "4 AM Flash Prep", "banter": "Adrenaline exam savior" },
    "countA": 1150,
    "countB": 1340,
    "totalVotes": 2490
  }
]

```

---

## 10. Verification, Testing & Production Release Plan

* **Unit Testing (`test/unit/question_model_test.dart`):**
* Assert `percentA` and `percentB` handle zero `totalVotes` without `DivisionByZero` or `NaN` exceptions (fallback to 50.0%).
* Assert `totalVotes == countA + countB`.


* **Integration & Security Testing:**
* Validate with the Firebase Local Emulator Suite:
* Anonymous user can update `countA` or `countB` and `totalVotes` by exactly 1.
* Attempts to increment `countA` without `totalVotes` fail.
* Multiple rapid clicks on a card trigger only one network write due to Hive local state pre-checks.




* **Android Release Preparation:**
* Configure `android/app/build.gradle`:
* Minimum SDK: `21`
* Target SDK: `34`


* Add Internet permission to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>

```


* Generate upload keystore and build app bundle:
```bash
flutter build appbundle --release

```




* **iOS Release Preparation:**
* Add photo capture and share permission entries to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save voting summary cards to share on your social status.</string>

```


* Build archive:
```bash
flutter build ipa --release

```