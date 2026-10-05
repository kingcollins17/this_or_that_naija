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
        color: isUserPick ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
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
