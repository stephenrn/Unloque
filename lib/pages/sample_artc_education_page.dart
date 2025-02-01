import 'package:flutter/material.dart';

class SampleArtcEducationPage extends StatelessWidget {
  const SampleArtcEducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sample Article Education Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Sample Article Education Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
