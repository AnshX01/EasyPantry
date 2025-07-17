import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsedWastedScreen extends StatefulWidget {
  const UsedWastedScreen({super.key});

  @override
  State<UsedWastedScreen> createState() => _UsedWastedScreenState();
}

class _UsedWastedScreenState extends State<UsedWastedScreen> {
  bool isLoading = true;
  List<dynamic> used = [];
  List<dynamic> wasted = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final u = await ApiService.fetchUsedItems();
    final w = await ApiService.fetchWastedItems();

    setState(() {
      used = u;
      wasted = w;
      isLoading = false;
    });
  }

  Widget buildItemCard(item) {
    final dateAdded = DateTime.tryParse(item['dateAdded'] ?? '');
    final expiryDate = DateTime.tryParse(item['expiryDate'] ?? '');

    String formatDate(DateTime? dt) {
      if (dt == null) return '';
      return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }

    return Card(
      child: ListTile(
        title: Text(item['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quantity: ${item['quantity']}"),
            if (expiryDate != null) Text("Expiry: ${formatDate(expiryDate)}"),
            if (dateAdded != null) Text("Added on: ${formatDate(dateAdded)}"),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Item History"),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          bottom: TabBar(
            labelColor: Theme.of(context).textTheme.bodyLarge?.color,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).textTheme.bodyLarge?.color,
            tabs: const [
              Tab(text: "Used"),
              Tab(text: "Wasted"),
            ],
          ),
        ),

        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                ListView(children: used.map(buildItemCard).toList()),
                ListView(children: wasted.map(buildItemCard).toList()),
              ]),
      ),
    );
  }
}
