import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> groceryItems = [];
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadGroceryItems();
  }

  Future<void> loadGroceryItems() async {
    final items = await ApiService.fetchGroceryItems();
    setState(() {
      groceryItems = items;
    });
  }

  Future<void> addItem() async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    final unit = unitController.text.trim();

    if (name.isEmpty || unit.isEmpty) return;

    await ApiService.addGroceryItem(name, quantity, unit);
    nameController.clear();
    quantityController.clear();
    unitController.clear();
    loadGroceryItems();
  }

  Future<void> deleteItem(String id) async {
    await ApiService.deleteGroceryItem(id);
    loadGroceryItems();
  }

  void showEditDialog(GroceryItem item) {
    final editNameController = TextEditingController(text: item.name);
    final editQuantityController = TextEditingController(text: item.quantity.toString());
    final editUnitController = TextEditingController(text: item.unit);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.black : Colors.white,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(labelText: 'Name'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            TextField(
              controller: editQuantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            TextField(
              controller: editUnitController,
              decoration: const InputDecoration(labelText: 'Unit'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final updatedName = editNameController.text.trim();
              final updatedQuantity = int.tryParse(editQuantityController.text.trim()) ?? 1;
              final updatedUnit = editUnitController.text.trim();

              if (updatedName.isEmpty || updatedUnit.isEmpty) return;

              await ApiService.updateGroceryItem(item.id, updatedName, updatedQuantity, updatedUnit);
              Navigator.pop(context);
              loadGroceryItems();
            },
            child: Text("Save", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }

  void showAddDialog() {
    nameController.clear();
    quantityController.clear();
    unitController.clear();
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.black : Colors.white,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        title: const Text("Add Grocery Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addItem();
            },
            child: Text("Add", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }

  
  Future<void> markAsPurchased(String id) async {
      await deleteItem(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as purchased")));
    }
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
              ),
              IconButton(
                icon: Icon(Icons.add, color: textColor),
                onPressed: showAddDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: groceryItems.isEmpty
              ? Center(
                  child: Text("No items in the grocery list.", style: TextStyle(color: textColor)),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: groceryItems.length,
                  itemBuilder: (context, index) {
                    final item = groceryItems[index];
                    return Dismissible(
                      key: ValueKey(item.id),
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
                          await markAsPurchased(item.id);
                        } else {
                          await deleteItem(item.id);
                        }
                        return false;
                      },
                      child: Card(
                        color: bgColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            '${item.name} - ${item.quantity} ${item.unit}',
                            style: TextStyle(color: textColor),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: textColor),
                            onPressed: () => showEditDialog(item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
