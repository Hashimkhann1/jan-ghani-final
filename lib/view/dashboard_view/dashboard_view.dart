import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          Center(child: Text("Dashboard View",style: TextStyle(fontSize: 22),),)
          
        ],
      ),
    );
  }
}
