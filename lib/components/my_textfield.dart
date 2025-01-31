import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final controller;
  final String label;
  final String hint;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 85,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Upper half - Label
          Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                label, //variable label
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.black,
          ),
          // Lower half - Input Field
          Expanded(
            child: TextField(
              controller: controller, //variable controller
              obscureText: obscureText, //variable obscureText
              decoration: InputDecoration(
                hintText: hint, //variable hint
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
