import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  void handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final response = await ApiService.registerUser(
      nameController.text,
      emailController.text,
      passwordController.text,
    );
    setState(() => isLoading = false);
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful. Please login.")),
      );
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Register on ScanIt", style: TextStyle(fontSize: 28)),
                const SizedBox(height: 30),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (val) =>
                      val == null || !val.contains('@') ? 'Invalid email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (val) =>
                      val == null || val.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
