import 'package:flutter/material.dart';
import 'recommendation_screen.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prediction")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text("Predicted Intake"),
                subtitle: Text("2450 kcal"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("View Recommendation"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecommendationScreen(),
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
