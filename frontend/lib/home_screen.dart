import 'package:flutter/material.dart';
import 'prediction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Calorie Dashboard",
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Card(
              child: ListTile(
                title: const Text(
                  "Today's Calories",
                ),
                subtitle: const Text(
                  "1850 kcal",
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text(
                "Predict Tomorrow",
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PredictionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}