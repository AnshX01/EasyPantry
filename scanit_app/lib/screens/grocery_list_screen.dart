import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
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
    final name = nameController.text;
    final quantity = int.tryParse(quantityController.text) ?? 1;
    final unit = unitController.text;

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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editNameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: editQuantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(controller: editUnitController, decoration: const InputDecoration(labelText: 'Unit')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final updatedName = editNameController.text.trim();
              final updatedQuantity = int.tryParse(editQuantityController.text.trim()) ?? 1;
              final updatedUnit = editUnitController.text.trim();

              if (updatedName.isEmpty || updatedUnit.isEmpty) return;

              await ApiService.updateGroceryItem(item.id, updatedName, updatedQuantity, updatedUnit);
              Navigator.pop(context);
              loadGroceryItems();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> markAsPurchased(String id) async {
    await deleteItem(id); // just remove it for now
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as purchased")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grocery List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item name')),
                TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: addItem, child: const Text('Add to List')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: groceryItems.length,
              itemBuilder: (context, index) {
                final item = groceryItems[index];
                return Card(
                  child: ListTile(
                    title: Text('${item.name} - ${item.quantity} ${item.unit}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showEditDialog(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => markAsPurchased(item.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
