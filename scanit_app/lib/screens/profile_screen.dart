import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '', email = '';
  bool isLoading = true;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await ApiService.getProfile();
    setState(() {
      name = data['name'] ?? '';
      email = data['email'] ?? '';
      _nameController.text = name;
      _emailController.text = email;
      isLoading = false;
    });
  }

  Future<void> updateProfile() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    final res = await ApiService.updateProfile({
      'name': _nameController.text,
      'email': _emailController.text,
    });

    if (res['message'] != null) {
      setState(() {
        isEditing = false;
        name = _nameController.text;
        email = _emailController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  void showPasswordDialog() {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    final confirmPwdController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildDialogTextField("Old Password", oldPwdController, obscure: true),
            buildDialogTextField("New Password", newPwdController, obscure: true),
            buildDialogTextField("Confirm New Password", confirmPwdController, obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark? Colors.white : Colors.black),),
          ),
          TextButton(
            onPressed: () async {
              if (newPwdController.text != confirmPwdController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }

              final res = await ApiService.changePassword(
                oldPwdController.text,
                newPwdController.text,
              );

              if (res['message'] != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(res['message'])));
              } else if (res['error'] != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(res['error'])));
              }
            },
            child: Text('Change', style: TextStyle(color: isDark? Colors.white : Colors.black),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    buildProfileField('Name', _nameController, isDark, isEditing),
                    buildProfileField('Email', _emailController, isDark, isEditing),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (isEditing) {
                              updateProfile();
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                          ),
                          child: Text(isEditing ? 'Save Info' : 'Edit Info'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: showPasswordDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                          ),
                          child: const Text("Edit Password"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildProfileField(
    String label,
    TextEditingController controller,
    bool isDark,
    bool editable,
  ) {
    return TextFormField(
      controller: controller,
      enabled: editable,
      validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget buildDialogTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
