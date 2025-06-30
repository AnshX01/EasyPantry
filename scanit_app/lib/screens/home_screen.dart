import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/theme_provider.dart';
import 'grocery_list_screen.dart';
import 'login_screen.dart';
import 'recipe_screen.dart';
import 'scan_screen.dart';
import 'used_wasted_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? email;
  bool isLoading = true;
  List<dynamic> items = [];

  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final expiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadEmailAndItems();
  }

  Future<void> loadEmailAndItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint('📦 Fetched token: $token');

    if (token == null || JwtDecoder.isExpired(token)) {
      debugPrint('❌ Token missing or expired. Redirecting to login...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final decoded = JwtDecoder.decode(token);
      final fetchedItems = await ApiService.fetchItems();

      setState(() {
        email = decoded['name'] ?? decoded['email'] ?? 'User';
        items = fetchedItems.where((item) {
          final expiry = DateTime.tryParse(item['expiryDate'] ?? '');
          return expiry != null && expiry.isAfter(DateTime.now());
        }).toList();
        isLoading = false;
      });

      for (int i = 0; i < fetchedItems.length; i++) {
        final item = fetchedItems[i];
        final expiryDate = DateTime.tryParse(item['expiryDate'] ?? '');
        if (expiryDate == null) continue;

        final daysLeft = expiryDate.difference(DateTime.now()).inDays;

        if (daysLeft <= 3 && daysLeft >= 0) {
          await NotificationService.showNotification(
            id: i,
            title: "Expiry Alert: ${item['name']}",
            body: "Expires in $daysLeft day(s)",
          );
        }

        if (daysLeft < 0) {
          Future.delayed(Duration(milliseconds: 300 * i), () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Item Expired: ${item['name']}"),
                content: const Text("Would you like to add this to your grocery list?"),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ApiService.autoWasteItem(item['_id']);
                      await loadEmailAndItems();
                    },
                    child: const Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await ApiService.addGroceryItemAutoSuggest(item['name']);
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${item['name']} added to grocery list")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to add')),
                        );
                      }
                      await ApiService.autoWasteItem(item['_id']);
                      await loadEmailAndItems();
                    },
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );
          });
        }

      }
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> handleAddItem() async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    final expiryDate = expiryController.text.trim();

    if (name.isEmpty || quantity <= 0 || expiryDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    final result = await ApiService.addItem(
      name: name,
      quantity: quantity,
      expiryDate: expiryDate,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item added")),
      );
      nameController.clear();
      quantityController.clear();
      expiryController.clear();
      await loadEmailAndItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to add item")),
      );
    }
  }

  void showEditDialog(Map<String, dynamic> item) {
    final quantityController = TextEditingController(text: item['quantity'].toString());
    final expiryController = TextEditingController(text: item['expiryDate']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${item['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            TextField(
              controller: expiryController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Expiry Date",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(item['expiryDate']) ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) {
                      expiryController.text = "${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final updatedQuantity = int.tryParse(quantityController.text) ?? 1;
              final updatedExpiry = expiryController.text;

              final result = await ApiService.updateItem(
                id: item['_id'],
                quantity: updatedQuantity,
                expiryDate: updatedExpiry,
              );

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Item updated")),
                );
                Navigator.pop(context);
                await loadEmailAndItems();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Update failed")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void handleLogout() async {
    await ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ScanIt Home"),
        actions: [
          const Icon(Icons.bedtime),
          const SizedBox(width: 5),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: Colors.yellow,
              inactiveThumbColor: Colors.grey,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsedWastedScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome, $email 👋", style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Item Name"),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: "Quantity"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: expiryController,
                    readOnly: false,
                    decoration: InputDecoration(
                      labelText: "Expiry Date (YYYY-MM-DD)",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 0)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (selectedDate != null) {
                            expiryController.text = selectedDate.toIso8601String().split('T')[0];
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: handleAddItem,
                    label: const Text("Add Item"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.document_scanner),
                    label: const Text("Scan Item"),
                    onPressed: () async {
                      final scanned = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );

                      if (scanned != null && scanned is Map<String, dynamic>) {
                        nameController.text = scanned['name'] ?? '';
                        quantityController.text = scanned['quantity']?.toString() ?? '';
                        expiryController.text = scanned['expiryDate'] ?? '';

                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text("View Stats"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text("Grocery List"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GroceryListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text("Get Recipes"),
                    onPressed: () async {
                      final response = await ApiService.fetchRecipes();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeScreen(recipes: response['recipes']),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Your Items:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: items.isEmpty
                        ? const Text("No items yet.")
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final expiryDate = DateTime.tryParse(item['expiryDate'] ?? '') ?? DateTime.now();
                              final daysLeft = expiryDate.difference(DateTime.now()).inDays;
                              final dateAdded = DateTime.tryParse(item['dateAdded'] ?? '');
                              final addedText = dateAdded != null
                                  ? "Added on: ${dateAdded.year.toString().padLeft(4, '0')}-${dateAdded.month.toString().padLeft(2, '0')}-${dateAdded.day.toString().padLeft(2, '0')}"
                                  : "";
                              Color getColor() {
                                if (daysLeft < 0) return Colors.red;
                                if (daysLeft <= 3) return Colors.orange;
                                return Colors.green;
                              }

                              return Dismissible(
                                key: ValueKey(item['_id']),
                                background: Container(
                                  color: Colors.green,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(Icons.check, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete_forever, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    final res = await ApiService.markItemUsed(item['_id']);
                                    if (res['success'] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Marked as used")),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(res['message'] ?? 'Failed')),
                                      );
                                    }
                                  } else {
                                    final res = await ApiService.markItemWasted(item['_id']);
                                    if (res['success'] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Marked as wasted")),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(res['message'] ?? 'Failed')),
                                      );
                                    }
                                  }
                                  await loadEmailAndItems();
                                  return false;
                                },
                                child: Card(
                                  color: getColor().withOpacity(0.1),
                                  child: ListTile(
                                    leading: Icon(Icons.inventory, color: getColor()),
                                    title: Text("${item['name']}"),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Quantity: ${item['quantity']}"),
                                        Text("Expires in: $daysLeft days"),
                                        if (addedText.isNotEmpty) Text(addedText),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => showEditDialog(item),
                                        ),
                                        Icon(Icons.calendar_month, color: getColor()),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
