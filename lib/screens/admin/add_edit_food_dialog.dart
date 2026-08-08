import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/admin_food_service.dart';

class AddEditFoodDialog extends StatefulWidget {
  final Map<String, dynamic>? food;

  const AddEditFoodDialog({super.key, this.food});

  @override
  State<AddEditFoodDialog> createState() => _AddEditFoodDialogState();
}

class _AddEditFoodDialogState extends State<AddEditFoodDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _saving = false;

  bool get isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    final food = widget.food;
    _nameController = TextEditingController(text: food?["food_name"]?.toString() ?? "");
    _caloriesController = TextEditingController(text: food?["calories"]?.toString() ?? "");
    _proteinController = TextEditingController(text: food?["protein"]?.toString() ?? "");
    _carbsController = TextEditingController(text: food?["carbs"]?.toString() ?? "");
    _fatController = TextEditingController(text: food?["fat"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  String? _requiredNumber(String? value, {double max = 9999}) {
    if (value == null || value.trim().isEmpty) return "Required";
    final parsed = double.tryParse(value);
    if (parsed == null) return "Enter a valid number";
    if (parsed < 0 || parsed > max) return "Must be between 0 and $max";
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final service = AdminFoodService(provider.authToken ?? "");

    final name = _nameController.text.trim();
    final calories = double.parse(_caloriesController.text);
    final protein = double.parse(_proteinController.text);
    final carbs = double.parse(_carbsController.text);
    final fat = double.parse(_fatController.text);

    try {
      if (isEditing) {
        await service.updateFood(
          foodId: widget.food!["food_id"],
          foodName: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
      } else {
        await service.createFood(
          foodName: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? "Edit Food" : "Add Food"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Food name"),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? "Must be at least 2 characters"
                    : null,
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: "Calories (kcal)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _requiredNumber,
              ),
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: "Protein (g)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _requiredNumber(v, max: 999),
              ),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(labelText: "Carbs (g)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _requiredNumber(v, max: 999),
              ),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(labelText: "Fat (g)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _requiredNumber(v, max: 999),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}
