import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WellnessTrackerPage extends StatefulWidget {
  const WellnessTrackerPage({super.key});

  @override
  State<WellnessTrackerPage> createState() => _WellnessTrackerPageState();
}

class _WellnessTrackerPageState extends State<WellnessTrackerPage> {
  double _water = 6;
  double _meals = 3;
  double _movement = 20;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final householdId = user.data()?['householdId'] as String?;
      if (householdId == null) {
        throw StateError('No family profile found.');
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('healthLogs')
          .doc('wellness-$dateKey')
          .set({
            'type': 'wellness',
            'dateKey': dateKey,
            'waterGlasses': _water.round(),
            'balancedMeals': _meals.round(),
            'movementMinutes': _movement.round(),
            'createdBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today’s wellness check-in was saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition & wellness')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Today’s habits', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Record simple habits to identify useful trends over time.',
          ),
          const SizedBox(height: 24),
          _metric(
            'Water',
            '${_water.round()} glasses',
            Icons.water_drop_outlined,
            _water,
            0,
            12,
            (value) => setState(() => _water = value),
          ),
          _metric(
            'Balanced meals',
            '${_meals.round()} meals',
            Icons.restaurant_outlined,
            _meals,
            0,
            6,
            (value) => setState(() => _meals = value),
          ),
          _metric(
            'Gentle movement',
            '${_movement.round()} minutes',
            Icons.directions_walk_outlined,
            _movement,
            0,
            60,
            (value) => setState(() => _movement = value),
          ),
          const SizedBox(height: 16),
          BZButton(
            label: 'Save today',
            onPressed: _save,
            isLoading: _saving,
            icon: Icons.check,
          ),
          const SizedBox(height: 16),
          const BZCard(
            child: Text(
              'Follow the advice of your maternity care professional. Hydration, nutrition and activity needs can differ during pregnancy.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    String valueLabel,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BZCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: BebezenPalette.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(valueLabel),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: valueLabel,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
