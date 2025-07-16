import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/login_screen.dart';
import '../screens/used_wasted_screen.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final Widget? bottomNavigation;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.bottomNavigation,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("View History"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsedWastedScreen()),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => SwitchListTile(
                secondary: const Icon(Icons.brightness_6),
                title: const Text("Dark Theme"),
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  Navigator.pop(context);
                  themeProvider.toggleTheme();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await ApiService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: body,
      bottomNavigationBar: bottomNavigation,
      floatingActionButton: FloatingActionButton(
        tooltip: "Ask Assistant",
        child: const Icon(Icons.smart_toy_rounded),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
      ),
    );
  }
}
