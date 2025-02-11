import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Continue with Google");
      },
      child: Center(
        child: Container(
          width: 300,
          height: 45, // Make the button thinner
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1), // Add border
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/images/google.png',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold, // Make the label bold
                    color: Colors.grey[800], // Text color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}