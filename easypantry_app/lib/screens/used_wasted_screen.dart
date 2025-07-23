import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

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

  Widget buildItemCard(item, bool isDark) {
    final dateAdded = DateTime.tryParse(item['dateAdded'] ?? '');
    final expiryDate = DateTime.tryParse(item['expiryDate'] ?? '');

    String formatDate(DateTime? dt) {
      if (dt == null) return '';
      return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }

    return Card(
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        title: Text(
          item['name'],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quantity: ${item['quantity']}",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            if (expiryDate != null)
              Text(
                "Expiry: ${formatDate(expiryDate)}",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
            if (dateAdded != null)
              Text(
                "Added on: ${formatDate(dateAdded)}",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Item History"),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: isDark ? Colors.white : Colors.black,
          bottom: TabBar(
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: isDark ? Colors.white : Colors.black,
            tabs: const [
              Tab(text: "Used"),
              Tab(text: "Wasted"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ListView(children: used.map((item) => buildItemCard(item, isDark)).toList()),
                  ListView(children: wasted.map((item) => buildItemCard(item, isDark)).toList()),
                ],
              ),
      ),
    );
  }
}
