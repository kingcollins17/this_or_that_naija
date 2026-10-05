import 'package:flutter_test/flutter_test.dart';
import 'package:this_or_that_naija/models/question_model.dart';

void main() {
  group('QuestionModel Tests', () {
    test('percentA and percentB handle zero totalVotes cleanly without division by zero', () {
      const question = QuestionModel(
        id: 'test_001',
        category: 'chow',
        optionA: OptionData(text: 'Option A', banter: 'Banter A'),
        optionB: OptionData(text: 'Option B', banter: 'Banter B'),
        countA: 0,
        countB: 0,
        totalVotes: 0,
      );

      expect(question.percentA, 50.0);
      expect(question.percentB, 50.0);
      expect(question.percentA.isNaN, false);
      expect(question.percentB.isNaN, false);
    });

    test('percentA and percentB calculate correct percentages when votes exist', () {
      const question = QuestionModel(
        id: 'test_002',
        category: 'street',
        optionA: OptionData(text: 'Danfo', banter: 'Banter A'),
        optionB: OptionData(text: 'Keke', banter: 'Banter B'),
        countA: 75,
        countB: 25,
        totalVotes: 100,
      );

      expect(question.percentA, 75.0);
      expect(question.percentB, 25.0);
      expect(question.totalVotes, equals(question.countA + question.countB));
    });

    test('QuestionModel.fromFirestore parses valid map properly', () {
      final map = {
        'category': 'lifestyle',
        'optionA': {'text': 'Lekki', 'banter': 'Traffic'},
        'optionB': {'text': 'Ikeja', 'banter': 'Bustle'},
        'countA': 60,
        'countB': 40,
        'totalVotes': 100,
        'isActive': true,
      };

      final model = QuestionModel.fromFirestore(map, 'doc_123');

      expect(model.id, 'doc_123');
      expect(model.category, 'lifestyle');
      expect(model.optionA.text, 'Lekki');
      expect(model.optionB.text, 'Ikeja');
      expect(model.countA, 60);
      expect(model.countB, 40);
      expect(model.totalVotes, 100);
      expect(model.isActive, true);
    });
  });
}
