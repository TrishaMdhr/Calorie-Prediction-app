import 'package:flutter/material.dart';

class FoodLogScreen extends StatelessWidget {
  const FoodLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Log")),

      body: ListView(
        children: const [
          ListTile(title: Text("Pizza"), subtitle: Text("320 kcal")),

          ListTile(title: Text("Momo"), subtitle: Text("250 kcal")),
        ],
      ),
    );
  }
}
