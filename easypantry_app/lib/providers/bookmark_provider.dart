import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedRecipes = [];

  List<Map<String, dynamic>> get bookmarkedRecipes => _bookmarkedRecipes;

  BookmarkProvider() {
    loadBookmarks();
  }

  bool isBookmarked(dynamic recipeId) {
    return _bookmarkedRecipes.any((r) => r['id'] == recipeId);
  }

  void toggleBookmark(Map<String, dynamic> recipe) {
    final recipeId = recipe['id'];
    if (isBookmarked(recipeId)) {
      _bookmarkedRecipes.removeWhere((r) => r['id'] == recipeId);
    } else {
      _bookmarkedRecipes.add(recipe);
    }
    saveBookmarks();
    notifyListeners();
  }

  void saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_bookmarkedRecipes);
    await prefs.setString('bookmarkedRecipes', encoded);
  }

  void loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('bookmarkedRecipes');
    if (stored != null) {
      final decoded = jsonDecode(stored);
      _bookmarkedRecipes = List<Map<String, dynamic>>.from(decoded);
      notifyListeners();
    }
  }

  void clearBookmarks() async {
    _bookmarkedRecipes.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarkedRecipes');
    notifyListeners();
  }
}
