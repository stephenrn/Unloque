import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isLoading;
  final bool isOutlined;
  final bool isEnabled; // Add this property

  const MyButton({super.key, required this.onTap, required this.label, this.isLoading = false, this.isOutlined = false, this.isEnabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || !isEnabled ? null : onTap,
      child: Center(
        child: Container(
          width: 300,
          height: 45, // Make the button thinner
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: [const Color.fromARGB(255, 74, 148, 209), const Color.fromARGB(255, 41, 97, 143)], // Gradient from blue to dark blue
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: !isEnabled ? (isOutlined ? Colors.white : (isLoading ? Colors.grey[600] : Colors.grey[800])) : null,
            borderRadius: BorderRadius.circular(10),
            border: isOutlined && !isEnabled ? Border.all(color: Colors.black, width: 1) : null, // Add border if outlined and not enabled
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
                        color: isEnabled ? Colors.white : Colors.black, // Set color to white if enabled
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold, // Make the label bold
                    color: isEnabled ? Colors.white : (isOutlined ? Colors.grey[800] : Colors.white), // Change text color if outlined
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
