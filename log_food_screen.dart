import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import '../models/food_log_model.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key});
  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  String _mealType = 'Lunch';
  int _tab = 0;
  final List<String> _mealTypes = [
    'Breakfast', 'Lunch', 'Dinner', 'Snacks'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log food',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MEAL TYPE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: const InputDecoration(),
                  items: _mealTypes
                      .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _mealType = v!),
                ),
                const SizedBox(height: 16),
                const Text('ITEMS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _OptionButton(
                  icon: Icons.document_scanner_outlined,
                  title: 'SCAN FOOD',
                  subtitle: 'Scan barcode or take a photo',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(height: 10),
                _OptionButton(
                  icon: Icons.edit_outlined,
                  title: 'ENTER MANUALLY',
                  subtitle: 'Type in food details',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                const SizedBox(height: 10),
                _OptionButton(
                  icon: Icons.bookmark_outline,
                  title: 'SAVED FOOD MACROS',
                  subtitle: 'Use previously saved foods',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: [
              _ScanPanel(mealType: _mealType),
              _ManualPanel(mealType: _mealType),
              _SavedMacrosPanel(mealType: _mealType),
            ][_tab],
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? AppTheme.primary : Colors.grey),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primary : Colors.black)),
            Text(subtitle,
                style:
                const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

class _ScanPanel extends StatelessWidget {
  final String mealType;
  const _ScanPanel({required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('Scan your food',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                await picker.pickImage(source: ImageSource.camera);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Food not recognized. Please add manually.'),
                      action: SnackBarAction(
                        label: 'Add Manually',
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                await picker.pickImage(source: ImageSource.gallery);
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPanel extends StatefulWidget {
  final String mealType;
  const _ManualPanel({required this.mealType});
  @override
  State<_ManualPanel> createState() => _ManualPanelState();
}

class _ManualPanelState extends State<_ManualPanel> {
  final List<_FoodItem> _items = [_FoodItem()];

  void _saveToLog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    bool anyAdded = false;
    for (final item in _items) {
      final name = item.nameCtrl.text.trim();
      final cal = double.tryParse(item.calCtrl.text) ?? 0;
      if (name.isNotEmpty && cal > 0) {
        provider.addFoodLog(FoodLog(
          name: name,
          calories: cal,
          protein: double.tryParse(item.proteinCtrl.text) ?? 0,
          carbs: double.tryParse(item.carbsCtrl.text) ?? 0,
          fat: double.tryParse(item.fatCtrl.text) ?? 0,
          mealType: widget.mealType,
        ));
        anyAdded = true;
      }
    }
    if (anyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully Logged!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter food name and calories')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._items.asMap().entries.map((entry) => _FoodItemForm(
            item: entry.value,
            index: entry.key,
            canRemove: _items.length > 1,
            onRemove: () =>
                setState(() => _items.removeAt(entry.key)),
            onSaveToMacros: () {
              final name = entry.value.nameCtrl.text.trim();
              final cal =
                  double.tryParse(entry.value.calCtrl.text) ?? 0;
              if (name.isNotEmpty) {
                Provider.of<AppProvider>(context, listen: false)
                    .saveToMacros(FoodLog(
                  name: name,
                  calories: cal,
                  protein: double.tryParse(
                      entry.value.proteinCtrl.text) ??
                      0,
                  carbs: double.tryParse(
                      entry.value.carbsCtrl.text) ??
                      0,
                  fat:
                  double.tryParse(entry.value.fatCtrl.text) ??
                      0,
                  mealType: widget.mealType,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Saved to macros!'),
                      backgroundColor: Colors.green),
                );
              }
            },
          )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _items.add(_FoodItem())),
            icon: const Icon(Icons.add),
            label: const Text('Add Another Item'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveToLog,
            child: const Text('Save To Log'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FoodItem {
  final nameCtrl = TextEditingController();
  final calCtrl = TextEditingController();
  final proteinCtrl = TextEditingController();
  final carbsCtrl = TextEditingController();
  final fatCtrl = TextEditingController();
}

class _FoodItemForm extends StatelessWidget {
  final _FoodItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onSaveToMacros;

  const _FoodItemForm({
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onSaveToMacros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: item.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Food Item',
                isDense: true,
                hintText: 'e.g. Rice, Chicken',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border,
                color: AppTheme.primary),
            tooltip: 'Save to macros',
            onPressed: onSaveToMacros,
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red),
              onPressed: onRemove,
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: item.calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Calories', isDense: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: item.proteinCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Protein (g)', isDense: true),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: item.carbsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Carbs (g)', isDense: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: item.fatCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Fat (g)', isDense: true),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SavedMacrosPanel extends StatelessWidget {
  final String mealType;
  const _SavedMacrosPanel({required this.mealType});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final macros = provider.savedMacros;

    if (macros.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_outline, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('No saved food macros yet',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text(
                'Save foods from manual entry\nby tapping the bookmark icon',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: macros.length,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Icon(Icons.bookmark,
                color: AppTheme.primary, size: 20),
          ),
          title: Text(macros[i].name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${macros[i].calories.toInt()} kcal | P: ${macros[i].protein.toInt()}g C: ${macros[i].carbs.toInt()}g F: ${macros[i].fat.toInt()}g'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add_circle,
                    color: AppTheme.primary),
                onPressed: () {
                  provider.addFoodLog(FoodLog(
                    name: macros[i].name,
                    calories: macros[i].calories,
                    protein: macros[i].protein,
                    carbs: macros[i].carbs,
                    fat: macros[i].fat,
                    mealType: mealType,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to log!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red),
                onPressed: () => provider.deleteMacro(i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}