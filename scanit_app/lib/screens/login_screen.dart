import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  void handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final response = await ApiService.loginUser(
      emailController.text,
      passwordController.text,
    );
    setState(() => isLoading = false);

    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', response['token']);

      final decodedToken = JwtDecoder.decode(response['token']);
      await prefs.setString('user_name', decodedToken['name']);
      await prefs.setString('user_email', decodedToken['email']);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Login failed')),
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
                const Text("Login to ScanIt", style: TextStyle(fontSize: 28)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Invalid email'
                      : null,
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
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text("Don't have an account? Register here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
