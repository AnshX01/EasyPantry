import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? imageBytes;
  bool isLoading = false;

  Future<void> pickImageAndSendToBackend() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected")),
      );
      return;
    }

    final bytes = await picked.readAsBytes();

    setState(() {
      isLoading = true;
      imageBytes = bytes;
    });

    print("📤 Sending image to backend...");

    final result = await ApiService.sendBarcodeImageToBackend(bytes);

    setState(() => isLoading = false);

    print("📥 Backend response: $result");

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item added successfully!")),
      );
      Navigator.pop(context); // Or refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Scan failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Item")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : pickImageAndSendToBackend,
                icon: const Icon(Icons.photo_library),
                label: const Text("Upload Barcode Image"),
              ),
              const SizedBox(height: 20),
              if (imageBytes != null)
                Image.memory(imageBytes!, height: 200)
              else
                const Text("No image selected"),
              const SizedBox(height: 30),
              if (isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
