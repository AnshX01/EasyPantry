import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/bookmarked_recipes_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? Colors.black : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history,
                  color: isDark ? Colors.white : Colors.black),
              title: Text("View History",
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsedWastedScreen()),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => SwitchListTile(
                secondary: Icon(Icons.brightness_6,
                    color: isDark ? Colors.white : Colors.black),
                title: Text("Dark Theme",
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black)),
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  Navigator.pop(context);
                  themeProvider.toggleTheme();
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.bookmarks,
                  color: isDark ? Colors.white : Colors.black),
              title: Text('Bookmarked Recipes',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BookmarkedRecipesScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.person,
                  color: isDark ? Colors.white : Colors.black),
              title: Text("Profile",
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout,
                  color: isDark ? Colors.white : Colors.black),
              title: Text("Logout",
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
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
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
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
