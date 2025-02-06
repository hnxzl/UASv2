import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Events")),
      body: const Center(
        child: Text("Ini Pages Events", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
