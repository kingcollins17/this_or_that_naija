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
