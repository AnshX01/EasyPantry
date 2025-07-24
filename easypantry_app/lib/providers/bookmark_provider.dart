import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookmarkProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedRecipes = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get bookmarkedRecipes => _bookmarkedRecipes;
  bool get isLoading => _isLoading;

  Future<void> loadBookmarks() async {
    _isLoading = true;
    _bookmarkedRecipes = [];
    notifyListeners();

    try {
      final bookmarks = await ApiService.fetchBookmarkedRecipes();
      _bookmarkedRecipes = List<Map<String, dynamic>>.from(bookmarks);
    } catch (e) {
      print('Error loading bookmarks: $e');
      _bookmarkedRecipes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isBookmarked(int recipeId) {
    return _bookmarkedRecipes.any((recipe) => recipe['id'] == recipeId);
  }

  Future<void> toggleBookmark(Map<String, dynamic> recipe) async {
    try {
      await ApiService.toggleBookmark(recipe);
      
      await loadBookmarks();
      
    } catch (e) {
      print('Error syncing bookmark with backend: $e');
    }
  }

  void clearBookmarks() {
    _bookmarkedRecipes.clear();
    notifyListeners();
  }
}