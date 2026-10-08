import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';
import '../widgets/camera_overlay_painter.dart';
import 'review_receipt_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  Offset? _focusPoint;

  late AnimationController _scanAnimController;
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingOcr = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCam = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          backCam,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        nextMode = FlashMode.off;
        break;
    }
    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() => _focusPoint = details.localPosition);
    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  Future<void> _captureReceipt() async {
    if (_isProcessingOcr) return;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        await _processFile(File(xFile.path));
      } else {
        // Fallback to ImagePicker if camera hardware not available (e.g. desktop/emulator)
        _pickFromGallery();
      }
    } catch (e) {
      _showError('Capture failed: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        await _processFile(File(picked.path));
      }
    } catch (e) {
      _showError('Gallery selection failed: $e');
    }
  }

  Future<void> _processFile(File file) async {
    setState(() => _isProcessingOcr = true);
    try {
      final parsed = await _ocrService.processImageFile(file);

      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReviewReceiptScreen(
            imageFile: file,
            parsedResult: parsed,
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop(true); // Return to home/transactions list
      }
    } catch (e) {
      _showError('OCR processing failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessingOcr = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Scan Physical Receipt', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.torch
                  ? Icons.flash_on
                  : _flashMode == FlashMode.auto
                      ? Icons.flash_auto
                      : Icons.flash_off,
              color: _flashMode != FlashMode.off ? Colors.amber : Colors.white,
            ),
            tooltip: 'Toggle Flash',
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Select from Gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanRect = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.44),
            width: constraints.maxWidth * 0.85,
            height: constraints.maxHeight * 0.58,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Live camera preview or fallback UI
              if (_isCameraInitialized && _cameraController != null)
                GestureDetector(
                  onTapDown: (details) => _onTapToFocus(details, constraints),
                  child: Center(
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                      const SizedBox(height: 12),
                      const Text(
                        'Camera unavailable or initializing...',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image from Gallery'),
                      ),
                    ],
                  ),
                ),

              // Framing Crop Overlay CustomPainter with laser scan line
              AnimatedBuilder(
                animation: _scanAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CameraOverlayPainter(
                      scanWindow: scanRect,
                      scanLineProgress: _scanAnimController.value,
                    ),
                  );
                },
              ),

              // Tap-to-focus ring indicator
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 24,
                  top: _focusPoint!.dy - 24,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amberAccent, width: 2),
                    ),
                  ),
                ),

              // Guidance text banner
              Positioned(
                top: scanRect.top - 40,
                left: 20,
                right: 20,
                child: const Text(
                  'Align receipt within the frame for auto-detection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),

              // Bottom Control Bar
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery shortcut
                    IconButton(
                      icon: const Icon(Icons.photo, color: Colors.white, size: 32),
                      onPressed: _pickFromGallery,
                    ),

                    // Shutter Capture Button
                    GestureDetector(
                      onTap: _captureReceipt,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.black87, size: 30),
                          ),
                        ),
                      ),
                    ),

                    // Manual add or info placeholder
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white, size: 30),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tip: Tap screen to focus. Ensure good lighting for highest OCR accuracy.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Fullscreen OCR Processing Overlay
              if (_isProcessingOcr)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.cyanAccent),
                        SizedBox(height: 18),
                        Text(
                          'On-Device ML Kit Parsing Receipt...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Extracting Total, Date & Merchant heuristically',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

