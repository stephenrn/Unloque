import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isLoading;
  final bool isOutlined; // Add this property

  const MyButton({super.key, required this.onTap, required this.label, this.isLoading = false, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Center(
        child: Container(
          width: 300,
          height: 45, // Make the button thinner
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : (isLoading ? Colors.grey[600] : Colors.grey[800]),
            borderRadius: BorderRadius.circular(10),
            border: isOutlined ? Border.all(color: Colors.black, width: 2) : null, // Add border if outlined
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold, // Make the label bold
                    color: isOutlined ? Colors.black : Colors.white, // Change text color if outlined
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
