import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';

class RecipeScreen extends StatefulWidget {
  final List<dynamic> recipes;
  const RecipeScreen({super.key, required this.recipes});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<dynamic> filteredRecipes = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredRecipes = List.from(widget.recipes);
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRecipes = widget.recipes.where((recipe) {
        final title = recipe['title']?.toLowerCase() ?? '';
        return title.contains(searchQuery);
      }).toList();
    });
  }

  void launchRecipe(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch recipe URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintTextColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.white24 : Colors.black26;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Suggested Recipes',
          style: TextStyle(color: textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: updateSearch,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search recipes',
                hintStyle: TextStyle(color: hintTextColor),
                filled: true,
                fillColor: backgroundColor,
                prefixIcon: Icon(Icons.search, color: textColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textColor),
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredRecipes.isEmpty
          ? Center(
              child: Text(
                "No matching recipes found.",
                style: TextStyle(color: hintTextColor),
              ),
            )
          : ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return Card(
                  color: backgroundColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      recipe['title'] ?? 'Unnamed Recipe',
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      '${recipe['usedIngredientCount']} ingredients used',
                      style: TextStyle(color: hintTextColor),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
                    onTap: () => launchRecipe(recipe['sourceUrl'] ?? ''),
                  ),
                );
              },
            ),
    );
  }

}
