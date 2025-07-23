import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkedRecipesScreen extends StatelessWidget {
  const BookmarkedRecipesScreen({super.key});

  void launchRecipe(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final recipes = bookmarkProvider.bookmarkedRecipes;
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
      body: recipes.isEmpty
          ? Center(
              child: Text('No bookmarks yet.',
                  style: TextStyle(color: hintTextColor)))
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (_, i) {
                final recipe = recipes[i];
                final recipeId = recipe['id'];
                final isBookmarked = bookmarkProvider.isBookmarked(recipeId);

                return Card(
                  color: backgroundColor,
                  shape: RoundedRectangleBorder(
                    side:
                        BorderSide(color: isDark ? Colors.white : Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(recipe['title'],
                        style: TextStyle(color: textColor)),
                    subtitle: Text('Recipe ID: $recipeId',
                        style: TextStyle(color: hintTextColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: textColor,
                          ),
                          onPressed: () {
                            bookmarkProvider.toggleBookmark(recipe);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.open_in_new, color: textColor),
                          onPressed: () =>
                              launchRecipe(recipe['sourceUrl'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
