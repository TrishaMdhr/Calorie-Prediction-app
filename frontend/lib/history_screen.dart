import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "History",
        ),
      ),

      body: ListView(

        children: const [

          ListTile(
            title: Text("Day 1"),
            subtitle: Text("2100 kcal"),
          ),

          ListTile(
            title: Text("Day 2"),
            subtitle: Text("1950 kcal"),
          ),
        ],
      ),
    );
  }
}