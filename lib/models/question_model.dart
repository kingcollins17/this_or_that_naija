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
