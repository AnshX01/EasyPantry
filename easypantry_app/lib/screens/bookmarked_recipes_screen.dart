import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class BookmarkedRecipesScreen extends StatefulWidget {
  const BookmarkedRecipesScreen({super.key});

  @override
  State<BookmarkedRecipesScreen> createState() => _BookmarkedRecipesScreenState();
}

class _BookmarkedRecipesScreenState extends State<BookmarkedRecipesScreen> {
  late Future<void> _loadBookmarksFuture;

  @override
  void initState() {
    super.initState();
    _loadBookmarksFuture = Provider.of<BookmarkProvider>(context, listen: false).loadBookmarks();
  }

  void launchRecipe(Map<String, dynamic> recipe) async {
    final recipeId = recipe['id'];
    if (recipeId == null) return;
    
    final url = await ApiService.fetchRecipeUrl(recipeId);
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch URL: $url');
      }
    } else {
      print('Could not fetch recipe URL for ID: $recipeId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Recipes', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _loadBookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading bookmarks.', style: TextStyle(color: hintTextColor)));
          }

          return Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              final recipes = bookmarkProvider.bookmarkedRecipes;

              if (recipes.isEmpty) {
                return Center(
                  child: Text('No bookmarks yet.', style: TextStyle(color: hintTextColor)),
                );
              }

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (_, i) {
                  final recipe = recipes[i];
                  final recipeId = recipe['id'] as int;
                  final isBookmarked = bookmarkProvider.isBookmarked(recipeId);

                  return Card(
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(recipe['title'], style: TextStyle(color: textColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: textColor,
                            ),
                            onPressed: () {
                              bookmarkProvider.toggleBookmark(recipe);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.open_in_new, color: textColor),
                            onPressed: () {
                              launchRecipe(recipe);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}