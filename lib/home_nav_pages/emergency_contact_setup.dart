import 'package:bebezen/core/services/account_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyContactSetup extends StatefulWidget {
  const EmergencyContactSetup({super.key});

  @override
  State<EmergencyContactSetup> createState() => _EmergencyContactSetupState();
}

class _EmergencyContactSetupState extends State<EmergencyContactSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _relation;
  bool _saving = false;

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final householdId = await AccountService().currentHouseholdId();
      if (householdId == null) {
        throw StateError('No family profile found.');
      }
      await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('emergencyContacts')
          .add({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'relation': _relation,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save contact: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contact')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.emergency_outlined,
            color: BebezenPalette.error,
            size: 54,
          ),
          const SizedBox(height: 18),
          Text(
            'Add a trusted contact',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().length < 6
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _relation,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items:
                      const ['Partner', 'Mother', 'Doctor', 'Friend', 'Other']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _relation = value),
                  validator: (value) =>
                      value == null ? 'Select a relationship' : null,
                ),
                const SizedBox(height: 24),
                BZButton(
                  label: 'Save contact',
                  onPressed: _saveContact,
                  isLoading: _saving,
                  icon: Icons.save_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
