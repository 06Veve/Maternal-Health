import 'package:flutter/material.dart';

class HealthyTipsPage extends StatelessWidget {
  HealthyTipsPage({super.key});

  // Example tips data (you can later fetch from Firebase or an API)
  final List<Map<String, String>> tips = [
    {
      "title": "Stay Hydrated",
      "description": "Drink at least 8 glasses of water daily to stay hydrated during pregnancy.",
      "icon": "💧"
    },
    {
      "title": "Eat Nutritious Food",
      "description": "Include fruits, vegetables, and proteins in your meals for baby’s healthy growth.",
      "icon": "🥦"
    },
    {
      "title": "Exercise Safely",
      "description": "Light exercises like walking or prenatal yoga can boost energy and improve mood.",
      "icon": "🤰"
    },
    {
      "title": "Regular Checkups",
      "description": "Attend your prenatal checkups to track your baby’s development.",
      "icon": "🩺"
    },
    {
      "title": "Rest Well",
      "description": "Aim for 7–9 hours of quality sleep to support your body and your baby.",
      "icon": "😴"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Healthy Tips"),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Text(
                tip["icon"]!,
                style: const TextStyle(fontSize: 30),
              ),
              title: Text(
                tip["title"]!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  tip["description"]!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}