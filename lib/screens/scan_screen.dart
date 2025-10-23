import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture; 
  late List<CameraDescription> _cameras; 

  @override
  void initState() {
    super.initState();
    _initCamera(); 
  }

  // Fungsi untuk inisialisasi kamera
  void _initCamera() async {
    try {
      _cameras = await availableCameras(); // Dapatkan kamera
      _controller = CameraController(
        _cameras[0], // Gunakan kamera utama
        ResolutionPreset.medium,
      );
      // Assign future-nya ke variabel state
      _initializeControllerFuture = _controller.initialize();
      
      // Panggil setState agar build() tahu future-nya sudah ada
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error jika tidak ada kamera atau ada masalah lain
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inisialisasi kamera: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Pastikan controller di-dispose saat widget ditutup
    _controller.dispose();
    super.dispose();
  }

  // Fungsi OCR tetap sama
  Future<String> _ocrFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    return recognizedText.text;
  }

  // Fungsi ambil gambar tetap sama
  Future<void> _takePicture() async {
    try {
      // Pastikan future-nya sudah selesai
      await _initializeControllerFuture;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memproses OCR, mohon tunggu...'),
          duration: Duration(seconds: 2),
        ),
      );

      final XFile image = await _controller.takePicture();

      final ocrText = await _ocrFromFile(File(image.path));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(ocrText: ocrText),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat mengambil / memproses foto: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cek jika future-nya belum di-set (artinya _initCamera belum jalan)
    if (_initializeControllerFuture == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kamera OCR')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Gunakan FutureBuilder untuk menunggu inisialisasi kamera
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        // Jika future selesai (kamera siap)
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kamera OCR')),
            body: Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller), // Tampilkan preview
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera),
                    label: const Text('Ambil Foto & Scan'),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          // Jika ada error saat inisialisasi
           return Scaffold(
             appBar: AppBar(title: const Text('Kamera OCR')),
             body: Center(child: Text('Error: ${snapshot.error}')),
           );
        } else {
          // Jika future masih loading (proses inisialisasi)
          return Scaffold(
            appBar: AppBar(title: const Text('Kamera OCR')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}