class GroceryItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['_id'],
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }
}
