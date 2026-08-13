import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'models/ghar_item.dart';
import 'services/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'GharKiList',
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _itemController = TextEditingController();
  List<GharItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _refreshItems() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllItems();
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    final newItem = GharItem(title: text);
    await DatabaseHelper.instance.insertItem(newItem);
    _itemController.clear();
    await _refreshItems();
  }

  Future<void> _toggleItem(GharItem item) async {
    if (item.id == null) return;
    await DatabaseHelper.instance.toggleItemStatus(item.id!, !item.isCompleted);
    await _refreshItems();
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteItem(id);
    await _refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((i) => i.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GharKiList'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ShadCard(
              title: const Text('Add Household Item'),
              description: const Text('Items will be stored in local SQLite database.'),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton(
                    onPressed: _addItem,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 6),
                        Text('Add Item'),
                      ],
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ShadInput(
                  controller: _itemController,
                  placeholder: const Text('Enter grocery or item name...'),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Ghar List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ShadBadge(
                  child: Text('$completedCount / ${_items.length} Completed'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No items added yet. Add your first item above!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Checkbox(
                                  value: item.isCompleted,
                                  onChanged: (_) => _toggleItem(item),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isCompleted ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Text('Added ${item.createdAt.toString().split('.')[0]}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: item.id != null
                                      ? () => _deleteItem(item.id!)
                                      : null,
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
