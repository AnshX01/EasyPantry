import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookmarkProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedRecipes = [];

  List<Map<String, dynamic>> get bookmarkedRecipes => _bookmarkedRecipes;

  Future<void> loadBookmarks() async {
    try {
      final bookmarks = await ApiService.fetchBookmarkedRecipes();
      _bookmarkedRecipes =
          List<Map<String, dynamic>>.from(bookmarks); // from backend
      notifyListeners();
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }

  bool isBookmarked(dynamic recipeId) {
    return _bookmarkedRecipes.any((r) => r['id'] == recipeId);
  }

  Future<void> toggleBookmark(Map<String, dynamic> recipe) async {
    final recipeId = recipe['id'];
    if (isBookmarked(recipeId)) {
      _bookmarkedRecipes.removeWhere((r) => r['id'] == recipeId);
    } else {
      _bookmarkedRecipes.add(recipe);
    }
    notifyListeners();

    try {
      await ApiService.toggleBookmark(recipe);
    } catch (e) {
      print('Error syncing bookmark with backend: $e');
    }
  }

  void clearBookmarks() {
    _bookmarkedRecipes.clear();
    notifyListeners();
  }
}
