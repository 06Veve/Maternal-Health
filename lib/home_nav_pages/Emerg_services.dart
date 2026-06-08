
import 'package:bebezen/home.dart';
import 'package:bebezen/home_nav_pages/emergency_contact_setup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyServices extends StatefulWidget {
  const EmergencyServices({super.key});

  @override
  State<EmergencyServices> createState() => _EmergencyServicesState();
}

class _EmergencyServicesState extends State<EmergencyServices> {
  String? selectedReason;
  List<Map<String, dynamic>> emergencyContacts = [];

  final List<String> emergencyReasons = [
    "I'm in labor",
    "I'm bleeding heavily",
    "Severe abdominal pain",
    "High fever with complications",
    "Baby not moving normally",
    "Other emergency",
  ];

  @override
  void initState() {
    super.initState();
    _checkAndLoadContacts();
  }

  // Check if the user has at least one contact and load them
  Future<void> _checkAndLoadContacts() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("emergencyContacts")
        .get();

    if (snapshot.docs.isEmpty) {
      // Navigate to setup and wait for result
      final added = await Navigator.push(context, MaterialPageRoute(builder: (context)=> EmergencyContactSetup()));

      if (added == true) {
        // Reload contacts after returning
        final newSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("emergencyContacts")
            .get();

        if (mounted) {
          setState(() {
            emergencyContacts =
                newSnapshot.docs.map((doc) => doc.data()).toList();
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          emergencyContacts = snapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    }
  }


  // Call a contact
  Future<void> _callNumber(String number) async {
    final Uri url = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Send SMS to a contact
  Future<void> _sendSMS(String number) async {
    final Uri url = Uri(scheme: "sms", path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildEmergencyCard(),
              const SizedBox(height: 32),
              _buildReasonSelection(),
              const SizedBox(height: 40),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildContactsList(), // Display saved contacts
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: Colors.red.shade600,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SafeMama",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  "Emergency Services",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            "Need Emergency Help?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Get immediate emergency assistance",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: selectedReason != null ? _handleEmergencyRequest : null,
              child: const Text(
                "REQUEST EMERGENCY HELP",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Select Emergency Reason",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Please select the reason for your emergency",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ...emergencyReasons.map((reason) => _buildReasonCheckbox(reason)),
        ],
      ),
    );
  }

  Widget _buildReasonCheckbox(String reason) {
    final bool isSelected = selectedReason == reason;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade50 : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.red.shade300 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          reason,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.red.shade700 : const Color(0xFF2D3748),
          ),
        ),
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            selectedReason = value == true ? reason : null;
          });
        },
        activeColor: Colors.red.shade600,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              );
            },
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedReason != null
                  ? Colors.red.shade600
                  : Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: selectedReason != null ? 2 : 0,
            ),
            onPressed: selectedReason != null ? _handleEmergencyRequest : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  "Get Help Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectedReason != null ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Display saved emergency contacts
  Widget _buildContactsList() {
    if (emergencyContacts.isEmpty) {
      return const SizedBox(); // No contacts yet
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Emergency Contacts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...emergencyContacts.map((contact) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.red),
              title: Text(contact["name"] ?? "Unknown"),
              subtitle: Text(contact["relation"] ?? "Relation"),
              trailing: Wrap(
                spacing: 12,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () => _callNumber(contact["phone"] ?? ""),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sms, color: Colors.blue),
                    onPressed: () => _sendSMS(contact["phone"] ?? ""),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Confirm SOS
  void _handleEmergencyRequest() async {
    if (selectedReason == null) return;

    if (emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contacts available.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirm SOS"),
        content: Text(
          "Send emergency alert for: $selectedReason?\nThis will alert your emergency contacts.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _alertContacts();
            },
            child: const Text("Send SOS"),
          ),
        ],
      ),
    );
  }

  // Call all emergency contacts
  Future<void> _alertContacts() async {
    for (var contact in emergencyContacts) {
      final phone = contact["phone"] ?? "";
      if (phone.isNotEmpty) {
        await _callNumber(phone); // You can also send SMS here
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("SOS alert sent for: $selectedReason"),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }


}
