import 'package:bebezen/home.dart';
import 'package:bebezen/insights.dart';
import 'package:bebezen/messages.dart';
import 'package:bebezen/profile.dart';
import 'package:flutter/material.dart';
class ManageNavigation extends StatefulWidget {
  const ManageNavigation({super.key});

  @override
  State<ManageNavigation> createState() => _ManageNavigationState();
}

class _ManageNavigationState extends State<ManageNavigation> {

  List pages = [
    Home(),
    Insights(),
    MessagePage(),
    ProfilePage()

  ];

  int currentIndex = 0;
  void changepage(int index){
    setState(() {
      currentIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
          onTap: changepage,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month,), label: "Today"

        ),
        BottomNavigationBarItem(icon: Icon(Icons.insights,), label: "Insights"

        ),

        BottomNavigationBarItem(icon: Icon(Icons.psychology,), label: "AI"

        ),
        BottomNavigationBarItem(icon: Icon(Icons.person,), label: "Profile"

        ),

      ],),
    );

  }
}
