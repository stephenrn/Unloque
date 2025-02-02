import 'package:flutter/material.dart';

class SampleArtcHealthcarePage extends StatelessWidget {
  const SampleArtcHealthcarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sample Article Healthcare Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Sample Article Healthcare Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
