import 'package:bebezen/home_nav_pages/Emerg_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactSetup extends StatefulWidget {
  const EmergencyContactSetup({super.key});

  @override
  State<EmergencyContactSetup> createState() => _EmergencyContactSetupState();
}

class _EmergencyContactSetupState extends State<EmergencyContactSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? relation;
  Map<String, String>? emergencyContact;

  Future<void> _saveContact() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("emergencyContacts")
        .add({
      "name": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),

      "createdAt": DateTime.now(),
    });

    if (mounted) {
      Navigator.pop(context, true); // Return true so EmergencyServices reloads
    }
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  /// 🔹 Load saved contact from Firestore
  Future<void> _loadEmergencyContact() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore
        .collection("users")
        .doc(uid)
        .collection("emergencyContacts")
        .doc("primary") // only one contact for now
        .get();

    if (doc.exists) {
      setState(() {
        emergencyContact = Map<String, String>.from(doc.data()!);
      });
    }
  }

  /// 🔹 Save contact to Firestore
  Future<void> _saveEmergencyContact() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final data = {
      "name": _nameController.text,
      "phone": _phoneController.text,
      "relation": relation!,
    };

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("emergency_contact")
        .doc("primary")
        .set(data);


    setState(() {
      emergencyContact = Map<String, String>.from(data);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency contact saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Add Emergency Contact")),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (v) => v!.isEmpty ? "Enter a name" : null,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: "Phone"),
                      validator: (v) => v!.isEmpty ? "Enter a phone" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: relation,
                      decoration: const InputDecoration(
                        labelText: "Relation",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Partner", "Mother", "Doctor", "Friend", "Other"]
                          .map((rel) =>
                          DropdownMenuItem(
                            value: rel,
                            child: Text(rel),
                          ))
                          .toList(),
                      onChanged: (val) => setState(() => relation = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _saveContact();
                          if (_nameController.text.isEmpty ||
                              _phoneController.text.isEmpty ||
                              relation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill all fields"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            emergencyContact = {
                              "name": _nameController.text,
                              "phone": _phoneController.text,
                              "relation": relation!,
                            };
                          });
                        },
                        child: const Text(
                          "Save Contact",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )

                  ],
                )
            )
        )
    );
  }

}
