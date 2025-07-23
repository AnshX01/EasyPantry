import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grocery_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addItem({
    required String name,
    required int quantity,
    required String expiryDate,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final response = await http.post(
      Uri.parse('$baseUrl/api/items/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'quantity': quantity,
        'expiryDate': expiryDate,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> fetchItems() async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/items'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateItem({
    required String id,
    required int quantity,
    required String expiryDate,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/items/update/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quantity': quantity,
        'expiryDate': expiryDate,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/weekly'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('Response body: ${response.body}');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchCategoryBreakdown() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/category-breakdown'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body)['data'];
  }

  static Future<Map<String, dynamic>> fetchDailyTrend() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/daily-trend'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body)['data'];
  }
  static Future<List<GroceryItem>> fetchGroceryItems() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/grocery'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    return (data['items'] as List).map((json) => GroceryItem.fromJson(json)).toList();
  }

  static Future<void> addGroceryItem(String name, int quantity, String unit) async {
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/api/grocery'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'quantity': quantity, 'unit': unit}),
    );
  }

  static Future<void> deleteGroceryItem(String id) async {
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/api/grocery/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
  
  static Future<void> updateGroceryItem(String id, String name, int quantity, String unit) async {
    final token = await getToken();

    final uri = Uri.parse('$baseUrl/api/grocery/$id');
    await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'quantity': quantity,
        'unit': unit,
      }),
    );
  }


  static Future<Map<String, dynamic>> addGroceryItemAutoSuggest(String name) async {
    final token = await getToken();

    final uri = Uri.parse('$baseUrl/api/grocery');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'quantity': 1,
        'unit': '',
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> autoWasteItem(String itemId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/items/auto-waste/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'itemId': itemId}),
    );
    print("Auto-waste response status: ${response.statusCode}");
    print("Auto-waste response body: ${response.body}");

    try {
      return jsonDecode(response.body);
    } catch (e) {
      print("Failed to decode auto-waste response: $e");
      return { 'success': false, 'message': 'Invalid response from server' };
    }
  }




  static Future<Map<String, dynamic>> fetchDetailedStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/details'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to fetch detailed stats');
    }
  }

  static Future<Map<String, dynamic>> fetchRecipes() async {
    final token = await getToken();
    final userId = await getUserId();

    final uri = Uri.parse('$baseUrl/api/recipes/$userId');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    final data = jsonDecode(response.body);
    if (data['recipes'] == null || data['recipes'] is! List) {
      data['recipes'] = [];
    }

    return data;
  }


  static Future<String?> fetchRecipeUrl(int recipeId) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/recipes/info/$recipeId');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sourceUrl'];
    } else {
      print('Failed to fetch recipe info: ${response.statusCode}');
      return null;
    }
  }




  // static Future<Map<String, dynamic>> addItemFromBarcode(String barcode) async {
  //   final token = await getToken();
  //   if (token == null) {
  //     return {'success': false, 'message': 'No token found'};
  //   }

  //   final response = await http.post(
  //     Uri.parse('$baseUrl/api/items/barcode'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode({'barcode': barcode}),
  //   );

  //   return jsonDecode(response.body);
  // }

  // static Future<Map<String, dynamic>> sendBarcodeImageToBackend(Uint8List imageBytes) async {
  //   final token = await getToken();
  //   final uri = Uri.parse('$baseUrl/api/scan');
  //   final request = http.MultipartRequest('POST', uri)
  //     ..headers['Authorization'] = 'Bearer $token'
  //     ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'barcode.jpg'));

  //   final streamed = await request.send();
  //   final response = await http.Response.fromStream(streamed);
  //   return jsonDecode(response.body);
  // }




  // static Future<Map<String, dynamic>> fetchProductByBarcode(String barcode) async {
  //   final response = await http.get(
  //     Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     if (data['status'] == 1) {
  //       return {'success': true, 'product': data['product']};
  //     } else {
  //       return {'success': false, 'message': 'Product not found'};
  //     }
  //   } else {
  //     return {'success': false, 'message': 'API error'};
  //   }
  // }


  // static Future<Map<String, dynamic>> scanAndAddItem(Uint8List imageBytes) async {
  //   final uri = Uri.parse('$baseUrl/api/items/scan');
  //   final request = http.MultipartRequest('POST', uri);

  //   final token = await getToken();
  //   request.headers['Authorization'] = 'Bearer $token';

  //   request.files.add(http.MultipartFile.fromBytes(
  //     'image',
  //     imageBytes,
  //     filename: 'scan.jpg',
  //     contentType: MediaType('image', 'jpeg'),
  //   ));

  //   final streamedResponse = await request.send();
  //   final response = await http.Response.fromStream(streamedResponse);
  //   return jsonDecode(response.body);
  // }

  static Future<Map<String, dynamic>> markItemUsed(String itemId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/items/use/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markItemWasted(String itemId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/items/waste/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> fetchUsedItems() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/items/used'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> fetchWastedItems() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/items/wasted'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data..removeWhere((k, v) => v == null || v == '')),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword(String oldPwd, String newPwd) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/user/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldPassword': oldPwd,
        'newPassword': newPwd,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<void> toggleBookmark(dynamic recipe) async {
    final token = await getToken();
    final userId = await getUserId();

    final uri = Uri.parse('$baseUrl/api/recipes/bookmark');
    await http.post(uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'recipeId': recipe['id'],
        'recipeData': recipe,
      }),
    );
  }

  static Future<List<dynamic>> fetchBookmarkedRecipes() async {
    final token = await getToken();
    final userId = await getUserId();

    final uri = Uri.parse('$baseUrl/api/recipes/bookmarked/$userId');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    final data = jsonDecode(response.body);
    return data['bookmarks']?.map((e) => e['recipeData'])?.toList() ?? [];
  }


  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;

    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['id'];
  }
}
