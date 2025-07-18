import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';

import 'grocery_list_screen.dart';
import 'login_screen.dart';
import 'recipe_screen.dart';
import '../widgets/main_scaffold.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
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

    if (token == null || JwtDecoder.isExpired(token)) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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

        if (daysLeft < 0 && item['status'] != 'wasted') {
          final res = await ApiService.autoWasteItem(item['_id']);
          if (res['success'] == true) {
            Future.delayed(Duration(milliseconds: 300 * i), () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Item Expired: ${item['name']}"),
                  content: const Text("Add to grocery list?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("No")),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result =
                            await ApiService.addGroceryItemAutoSuggest(
                                item['name']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['success'] == true
                                  ? "${item['name']} added"
                                  : "Failed")),
                        );
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void showAddItemDialog() {
  nameController.clear();
  quantityController.clear();
  expiryController.clear();
  showItemDialog(isEdit: false);
}

void showEditItemDialog(Map<String, dynamic> item) {
  nameController.text = item['name'];
  quantityController.text = item['quantity'].toString();
  expiryController.text = item['expiryDate'] ?? '';
  showItemDialog(isEdit: true, itemId: item['_id']);
}

void showItemDialog({required bool isEdit, String? itemId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(isEdit ? "Edit Item" : "Add Item", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Item Name",
                labelStyle: TextStyle(color: textColor),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Quantity",
                labelStyle: TextStyle(color: textColor),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: expiryController,
              readOnly: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Expiry Date",
                labelStyle: TextStyle(color: textColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: textColor),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(expiryController.text) ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      expiryController.text = date.toIso8601String().split('T')[0];
                    }
                  },
                ),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: textColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () => isEdit ? handleUpdateItem(itemId!) : handleAddItem(),
            child: Text(isEdit ? "Save" : "Add"),
          ),
        ],
      ),
    );
  }

  Future<void> handleUpdateItem(String id) async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    final expiry = expiryController.text.trim();

    if (name.isEmpty || quantity <= 0 || expiry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid input")));
      return;
    }

    final result = await ApiService.updateItem(
      id: id,
      quantity: quantity,
      expiryDate: expiry,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['success'] == true ? "Updated" : "Update failed")),
    );
    await loadEmailAndItems();
  }


  Future<void> handleAddItem() async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    final expiry = expiryController.text.trim();

    if (name.isEmpty || quantity <= 0 || expiry.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid input")));
      return;
    }

    final result = await ApiService.addItem(
        name: name, quantity: quantity, expiryDate: expiry);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? "Added" : "Failed")));
    await loadEmailAndItems();
  }

  void handleLogout() async {
    await ApiService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget buildHomeView() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: loadEmailAndItems,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("Welcome $email!",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w400)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Your Active Ingredients",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w300)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: showAddItemDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const Text("No items yet.")
                else
                  ...items.map((item) {
                    final expiryDate =
                        DateTime.tryParse(item['expiryDate'] ?? '') ??
                            DateTime.now();
                    final daysLeft =
                        expiryDate.difference(DateTime.now()).inDays;

                    Color color;
                    if (daysLeft < 0) {
                      color = Colors.red;
                    } else if (daysLeft <= 3) {
                      color = Colors.orange;
                    } else {
                      color = Colors.green;
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['success'] == true ? "Marked as used" : "Failed")),
                          );
                        } else {
                          final res = await ApiService.markItemWasted(item['_id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['success'] == true ? "Marked as wasted" : "Failed")),
                          );
                        }
                        await loadEmailAndItems();
                        return false; // Prevent automatic dismiss
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: color.withOpacity(0.1),
                        child: ListTile(
                          leading: Icon(Icons.inventory, color: color),
                          title: Text(item['name']),
                          subtitle: Text("Qty: ${item['quantity']} • Expires in $daysLeft days"),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: color),
                            onPressed: () => showEditItemDialog(item),
                          ),
                        ),
                      ),
                    );

                  }),
              ],
            ),
          );
  }

  void onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    final pages = [
      buildHomeView(),
      const GroceryListScreen(),
      const StatsScreen(),
      FutureBuilder(
        future: ApiService.fetchRecipes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RecipeScreen(recipes: snapshot.data!['recipes']);
        },
      )
    ];

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return MainScaffold(
      title: "ScanIt",
      body: pages[_selectedIndex],
      bottomNavigation: BottomNavigationBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        currentIndex: _selectedIndex,
        onTap: onBottomNavTap,
        selectedItemColor: isDark ? Colors.white : Colors.black,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[700],
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Grocery"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Recipes"),
        ],
      ),
    );

  }
}
