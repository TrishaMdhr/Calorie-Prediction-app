// =============================================================================
// FILE: lib/screens/log_food_screen.dart
// ROLE: Food logging screen — 3 input methods
// -----------------------------------------------------------------------------
// TAB 0 — SCAN FOOD (_ScanPanel):
//   · Picks image from camera/gallery
//   · Sends to POST /predict (CNN food recognition)
//   · _saveToLog() → AppProvider.addFoodLog() → syncs to backend
//
// TAB 1 — ENTER MANUALLY (_ManualPanel):
//   · User types food name, calories, protein, carbs, fat
//   · Food name field has live autocomplete via FoodSearchService (GET /search)
//   · _saveToLog() → AppProvider.addFoodLog() → syncs to backend
//   · Bookmark icon → AppProvider.saveToMacros() (saves for reuse)
//
// TAB 2 — SAVED FOOD MACROS (_SavedMacrosPanel):
//   · Lists AppProvider.savedMacros
//   · "+" button → AppProvider.addFoodLog() → syncs to backend
//   · Trash icon → AppProvider.deleteMacro()
//
// All panels respect the Meal Type selector (Breakfast/Lunch/Dinner/Snacks)
// =============================================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import '../models/food_log_model.dart';
import '../services/food_dataset_service.dart';
import '../services/food_search_service.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key});
  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  String _mealType = 'Lunch';
  int _tab = 0;
  final List<String> _mealTypes = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack'
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
                   initialValue: _mealType,
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
            color: selected ? AppTheme.primary : Colors.transparent,
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

// ── CNN Food Scanner ──────────────────────────────────────────────
class _ScanPanel extends StatefulWidget {
  final String mealType;
  const _ScanPanel({required this.mealType});
  @override
  State<_ScanPanel> createState() => _ScanPanelState();
}

class _ScanPanelState extends State<_ScanPanel> {
  bool _scanning = false;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _result;
  String? _errorMsg;
  bool _isFromDataset = false;
  final _datasetService = FoodDatasetService();

  // Editable controllers — populated after scan, let user correct before saving
  final _nameCtrl = TextEditingController();
  final _calCtrl  = TextEditingController();
  final _proCtrl  = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _datasetService.load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _populateEditors(Map<String, dynamic> result) {
    _nameCtrl.text = result['name'] ?? '';
    _calCtrl.text  = '${result['calories'] ?? 0}';
    _proCtrl.text  = '${result['protein'] ?? 0}';
    _carbCtrl.text = '${result['carbs'] ?? 0}';
    _fatCtrl.text  = '${result['fat'] ?? 0}';
  }

  Future<void> _pickAndScan(ImageSource source) async {
    // Cache provider before any async gap
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 800);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _scanning = true;
        _imageBytes = bytes;
        _result = null;
        _errorMsg = null;
        _isFromDataset = false;
      });

      final data = await provider.predictFoodFromImage(bytes);

      if (!mounted) return;

      if (data != null && !data.containsKey('error')) {
        final foodName  = data['food'] as String;
        final calories  = (data['calories'] as num).toInt();
        final confidence = (data['confidence'] as num).toDouble();
        final protein   = (data['protein'] as num?)?.toDouble() ?? 0;
        final carbs     = (data['carbs'] as num?)?.toDouble() ?? 0;
        final fat       = (data['fat'] as num?)?.toDouble() ?? 0;

        // Enrich macros from local dataset if available
        final match = _datasetService.findMatch(foodName);

        final result = {
          'name':            foodName,
          'calories':        calories,
          'protein':         match?.protein.round() ?? protein.round(),
          'carbs':           match?.carbs.round() ?? carbs.round(),
          'fat':             match?.fat.round() ?? fat.round(),
          'confidence':      confidence,
          'confidence_tier': data['confidence_tier'] ?? 'low',
        };
        setState(() {
          _result = result;
          _isFromDataset = match != null;
          _scanning = false;
        });
        _populateEditors(result);
      } else {
        setState(() {
          _errorMsg = data?['error'] ?? 'Could not recognize this food. Please add it manually.';
          _scanning = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Error accessing camera/gallery: $e';
        _scanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera/gallery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveToLog() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name'), backgroundColor: Colors.red),
      );
      return;
    }
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    if (cal <= 0 || cal > 9999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calories must be between 1 and 9999'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addFoodLog(FoodLog(
      name:     name,
      calories: cal,
      protein:  double.tryParse(_proCtrl.text) ?? 0,
      carbs:    double.tryParse(_carbCtrl.text) ?? 0,
      fat:      double.tryParse(_fatCtrl.text) ?? 0,
      mealType: widget.mealType,
    ));
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
  }

  void _addManually() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ManualPanel(mealType: widget.mealType),
    );
  }

  Widget _confidenceBanner(double confidence, String tier) {
    Color bgColor; IconData icon; String label;
    if (tier == 'high') {
      bgColor = Colors.green.shade50; icon = Icons.check_circle_outline; label = 'High confidence (${confidence.toStringAsFixed(1)}%) — result looks reliable';
    } else if (tier == 'medium') {
      bgColor = Colors.orange.shade50; icon = Icons.info_outline; label = 'Medium confidence (${confidence.toStringAsFixed(1)}%) — please verify the result';
    } else {
      bgColor = Colors.red.shade50; icon = Icons.warning_amber_rounded; label = 'Low confidence (${confidence.toStringAsFixed(1)}%) — result may be wrong, please correct below';
    }
    final textColor = tier == 'high' ? Colors.green.shade800 : tier == 'medium' ? Colors.orange.shade800 : Colors.red.shade800;
    final borderColor = tier == 'high' ? Colors.green.shade200 : tier == 'medium' ? Colors.orange.shade200 : Colors.red.shade200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(icon, color: textColor, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: textColor, fontSize: 12))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 20),
            Text('Analyzing your food…',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('This may take up to 60 s on first scan\n(model is loading)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    if (_result != null) {
      final conf = (_result!['confidence'] as num).toDouble();
      final tier = _result!['confidence_tier'] as String? ?? 'low';
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview image
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(_imageBytes!,
                    height: 170, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

            // Confidence banner
            _confidenceBanner(conf, tier),
            const SizedBox(height: 14),

            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isFromDataset ? Colors.blue.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFromDataset ? 'Macros from food database' : 'Macros estimated by CNN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: _isFromDataset ? Colors.blue : Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 14),

            // ── Editable result fields ──────────────
            const Text('FOOD DETAILS — tap any field to correct',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                prefixIcon: Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _proCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _carbCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _fatCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
            ]),
            const SizedBox(height: 20),

            // Action buttons
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveToLog,
                icon: const Icon(Icons.check),
                label: const Text('Save To Log'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _result = null;
                  _imageBytes = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          if (_imageBytes != null && _errorMsg != null) ...[
      ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(_imageBytes!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover),
    ),
    const SizedBox(height: 16),
    Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
    color: Colors.orange.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color: Colors.orange.withValues(alpha: 0.4)),
    ),
    child: Row(children: [
    const Icon(Icons.warning_amber_rounded,
    color: Colors.orange),
    const SizedBox(width: 10),
    Expanded(
    child: Text(_errorMsg!,
    style: const TextStyle(
    color: Colors.orange)),
    ),
    ]),
    ),
    const SizedBox(height: 20),
    ElevatedButton.icon(
    onPressed: _addManually,
    icon: const Icon(Icons.edit),
    label: const Text('Add Manually'),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
    onPressed: () => setState(() {
    _imageBytes = null;
    _errorMsg = null;
    }),
    icon: const Icon(Icons.refresh),
    label: const Text('Try Again'),
    ),
    ] else ...[
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Take a photo and we\'ll fill in\nthe nutrition details for you',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  _pickAndScan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _pickAndScan(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from Gallery'),
            ),
          ],
              ],
          ),
      ),
    );
  }
}

// ── Manual Panel ──────────────────────────────────────────────────
class _ManualPanel extends StatefulWidget {
  final String mealType;
  const _ManualPanel({required this.mealType});
  @override
  State<_ManualPanel> createState() => _ManualPanelState();
}

class _ManualPanelState extends State<_ManualPanel> {
  final _formKey = GlobalKey<FormState>();
  final List<_FoodItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items.add(_createItem());
  }

  _FoodItem _createItem() {
    final item = _FoodItem();
    item.calCtrl.addListener(_onFieldChanged);
    item.proteinCtrl.addListener(_onFieldChanged);
    item.carbsCtrl.addListener(_onFieldChanged);
    item.fatCtrl.addListener(_onFieldChanged);
    return item;
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.calCtrl.removeListener(_onFieldChanged);
      item.proteinCtrl.removeListener(_onFieldChanged);
      item.carbsCtrl.removeListener(_onFieldChanged);
      item.fatCtrl.removeListener(_onFieldChanged);
      item.dispose();
    }
    super.dispose();
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      final item = _items.removeAt(index);
      item.calCtrl.removeListener(_onFieldChanged);
      item.proteinCtrl.removeListener(_onFieldChanged);
      item.carbsCtrl.removeListener(_onFieldChanged);
      item.fatCtrl.removeListener(_onFieldChanged);
      item.dispose();
      setState(() {});
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_createItem());
    });
  }

  String? _getMacroWarning(_FoodItem item) {
    final calStr = item.calCtrl.text.trim();
    final proStr = item.proteinCtrl.text.trim();
    final carbStr = item.carbsCtrl.text.trim();
    final fatStr = item.fatCtrl.text.trim();

    if (calStr.isEmpty) return null;

    final cal = double.tryParse(calStr) ?? 0;
    if (cal <= 0) return null;

    // If all macros are empty, do not warn (optional fields)
    if (proStr.isEmpty && carbStr.isEmpty && fatStr.isEmpty) return null;

    final p = double.tryParse(proStr) ?? 0;
    final c = double.tryParse(carbStr) ?? 0;
    final f = double.tryParse(fatStr) ?? 0;

    final estCal = (p * 4) + (c * 4) + (f * 9);
    final difference = (estCal - cal).abs();
    final percentDiff = cal == 0 ? 0.0 : (difference / cal);

    if (percentDiff > 0.3 && difference > 50) {
      return '⚠️ Macros sum to ${estCal.round()} kcal, which deviates from entered calories by ${(percentDiff * 100).round()}%';
    }
    return null;
  }

  void _saveToLog() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final warning = _getMacroWarning(item);

              return _FoodItemForm(
                item: item,
                index: index,
                canRemove: _items.length > 1,
                onRemove: () => _removeItem(index),
                macroWarning: warning,
                onFieldChanged: _onFieldChanged,
                onSaveToMacros: () {
                  if (!_formKey.currentState!.validate()) return;
                  final name = item.nameCtrl.text.trim();
                  final cal = double.tryParse(item.calCtrl.text) ?? 0;
                  if (name.isNotEmpty) {
                    Provider.of<AppProvider>(context, listen: false)
                        .saveToMacros(FoodLog(
                      name: name,
                      calories: cal,
                      protein: double.tryParse(item.proteinCtrl.text) ?? 0,
                      carbs: double.tryParse(item.carbsCtrl.text) ?? 0,
                      fat: double.tryParse(item.fatCtrl.text) ?? 0,
                      mealType: widget.mealType,
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to macros!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Item'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveToLog,
                child: const Text('Save To Log'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
  bool isFromDatabase = false;

  void dispose() {
    nameCtrl.dispose();
    calCtrl.dispose();
    proteinCtrl.dispose();
    carbsCtrl.dispose();
    fatCtrl.dispose();
  }
}

class _FoodItemForm extends StatefulWidget {
  final _FoodItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onSaveToMacros;
  final VoidCallback onFieldChanged;
  final String? macroWarning;

  const _FoodItemForm({
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onSaveToMacros,
    required this.onFieldChanged,
    this.macroWarning,
  });

  @override
  State<_FoodItemForm> createState() => _FoodItemFormState();
}

class _FoodItemFormState extends State<_FoodItemForm> {
  final _searchService = FoodSearchService();
  Timer? _debounce;
  List<SearchedFood> _results = [];
  bool _searching = false;
  bool _showDropdown = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    widget.item.isFromDatabase = false;

    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _showDropdown = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      final results = await _searchService.search(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        _showDropdown = results.isNotEmpty;
      });
    });
  }

  void _selectFood(SearchedFood food) {
    setState(() {
      widget.item.nameCtrl.text = food.name;
      widget.item.calCtrl.text = food.calories.round().toString();
      widget.item.proteinCtrl.text = food.protein.round().toString();
      widget.item.carbsCtrl.text = food.carbs.round().toString();
      widget.item.fatCtrl.text = food.fat.round().toString();
      widget.item.isFromDatabase = true;
      _showDropdown = false;
      _results = [];
    });
    widget.onFieldChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canRemove = widget.canRemove;
    final onRemove = widget.onRemove;
    final onSaveToMacros = widget.onSaveToMacros;
    final macroWarning = widget.macroWarning;

    final numFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

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
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: item.nameCtrl,
                      onChanged: _onNameChanged,
                      decoration: InputDecoration(
                        labelText: 'Food Item',
                        isDense: true,
                        hintText: 'e.g. Rice, Chicken',
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name required';
                        }
                        if (v.trim().length < 2) {
                          return 'At least 2 characters';
                        }
                        return null;
                      },
                    ),
                    if (_showDropdown)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final food = _results[i];
                            return ListTile(
                              dense: true,
                              title: Text(food.name),
                              subtitle: Text(
                                '${food.calories.round()} kcal | '
                                'P:${food.protein.round()} '
                                'C:${food.carbs.round()} '
                                'F:${food.fat.round()}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => _selectFood(food),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: AppTheme.primary),
                tooltip: 'Save to macros',
                onPressed: onSaveToMacros,
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (item.isFromDatabase) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Macros from food database',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.calCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Calories required';
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid number';
                    if (n <= 0) return 'Must be > 0';
                    if (n > 9999) return 'Max 9999 kcal';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: item.proteinCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid';
                    if (n < 0) return 'Must be >= 0';
                    if (n > 999) return 'Max 999g';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.carbsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Carbs (g)',
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid';
                    if (n < 0) return 'Must be >= 0';
                    if (n > 999) return 'Max 999g';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: item.fatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [numFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null) return 'Invalid';
                    if (n < 0) return 'Must be >= 0';
                    if (n > 999) return 'Max 999g';
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (macroWarning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                macroWarning,
                style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Saved Macros Panel ────────────────────────────────────────────
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
              Icon(Icons.bookmark_outline,
                  size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('No saved food macros yet',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
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
            backgroundColor:
            AppTheme.primary.withOpacity(0.1),
            child: Icon(Icons.bookmark,
                color: AppTheme.primary, size: 20),
          ),
          title: Text(macros[i].name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600)),
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