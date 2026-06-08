import 'package:bebezen/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ---- LOGIC ----
  int calculateGestationalAge(Map<String, dynamic> data) {
    final int initialAge = data['gestationalAgeWeeks'] ?? 0;
    final Timestamp? refTs = data['gestationalReferenceDate'];
    if (refTs == null) return initialAge;

    final DateTime refDate = refTs.toDate();
    final int weeksPassed = DateTime.now().difference(refDate).inDays ~/ 7;

    return (initialAge + weeksPassed).clamp(0, 42); // cap at 42 weeks
  }

  DateTime? calculateDueDate(Map<String, dynamic> data) {
    final Timestamp? lmpTs = data['pregnancy']?['lmpEstimated'];
    if (lmpTs == null) return null;
    return lmpTs.toDate().add(const Duration(days: 280)); // 40 weeks
  }

  @override
  Widget build(BuildContext context) {
    Future<void> signout(BuildContext context) async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            onPressed: () => signout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.pinkAccent, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "Unable to load profile",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString().contains('permission')
                        ? "Permission denied. Contact support."
                        : "Check your internet connection.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final gestationalAge = calculateGestationalAge(data);
          final dueDate = calculateDueDate(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.pink[200],
                  child: const Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 12),
                Text(
                  "${user?.email?.split("@")[0] ?? 'User'}",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Pregnancy Week $gestationalAge",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // --- Personal Info Section ---
                _buildSection(
                  title: "Personal Info",
                  children: [
                    _InfoTile(
                        label: "Name",
                        value: "${user?.email?.split("@")[0] ?? 'User'}"),
                    const _InfoTile(label: "Age", value: "29"),
                    _InfoTile(
                      label: "Due Date",
                      value: dueDate != null
                          ? "${dueDate.toLocal().toString().split(' ')[0]}"
                          : "Not set",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Medical Info Section ---
                _buildSection(
                  title: "Medical Info",
                  children: const [
                    _InfoTile(label: "Blood Type", value: "O+"),
                    _InfoTile(label: "Allergies", value: "None"),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Settings Section ---
                _buildSection(
                  title: "Settings",
                  children: const [
                    _InfoTile(label: "Notifications", value: "Enabled"),
                    _InfoTile(label: "Language", value: "English"),
                    _InfoTile(label: "Privacy", value: "Standard"),
                  ],
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => signout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Log Out",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ],
      ),
    );
  }
}


/*class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> signout(BuildContext context) async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) =>  LoginPage()),
            (route) => false, // supprime toutes les anciennes routes
      );

    }
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(

        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(onPressed: () {
            signout(context);
          }, icon: Icon(Icons.logout))
        ],
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),
        child: Column(

          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.pink[200],
              child: Icon(Icons.person, size: 50,),
              /*backgroundImage: AssetImage("assets/profile.jpg"),*/ // Replace with real profile image
            ),
            const SizedBox(height: 12),
            Text(
              "${user?.email?.split("@")[0] ?? 'User'}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Pregnancy Week 15",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "Personal Info",
              children: [
                _InfoTile(label: "Name", value: "${user?.email?.split("@")[0] ?? 'User'}"),
                _InfoTile(label: "Age", value: "29"),
                _InfoTile(label: "Due Date", value: "Jun 8, 2024"),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              title: "Medical Info",
              children: const [
                _InfoTile(label: "Blood Type", value: "O+"),
                _InfoTile(label: "Allergies", value: "None"),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              title: "Settings",
              children: const [
                _InfoTile(label: "Notifications", value: "Enabled"),
                _InfoTile(label: "Language", value: "English"),
                _InfoTile(label: "Privacy", value: "Standard"),
              ],
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                signout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Log Out", style: TextStyle(fontSize: 16, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ],
      ),
    );
  }
}*/