import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Recipes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: updateSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900], // Dark background
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredRecipes.isEmpty
          ? const Center(child: Text("No matching recipes found."))
          : ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Image.network(
                      recipe['image'] ?? '',
                      width: 60,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                    title: Text(recipe['title'] ?? 'Unnamed Recipe'),
                    subtitle: Text('${recipe['usedIngredientCount']} ingredients used'),
                    onTap: () => launchRecipe(recipe['sourceUrl'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
