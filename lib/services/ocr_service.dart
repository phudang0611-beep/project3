import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'heuristic_parser.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Process an image file and return extracted heuristic data
  Future<ParsedReceiptResult> processImageFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return HeuristicParser.parse(recognizedText.text);
  }

  /// Process image from file path directly
  Future<ParsedReceiptResult> processImagePath(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return HeuristicParser.parse(recognizedText.text);
  }

  /// Get raw recognized string
  Future<String> getRawText(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
