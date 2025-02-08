import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Widget route;
  final String label;

  const MyButton({super.key, required this.route, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => route),
        );
      },
      child: Container(
        width: 350,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
