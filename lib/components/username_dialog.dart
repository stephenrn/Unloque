import 'package:flutter/material.dart';
import 'my_textfield.dart';

class UsernameDialog extends StatefulWidget {
  @override
  _UsernameDialogState createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isValid = false;

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.length >= 3 && value.length <= 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Username',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose a username between 3-20 characters',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            MyTextfield(
              controller: _usernameController,
              label: 'Username',
              hint: 'Enter username',
              obscureText: false,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isValid
                  ? () => Navigator.pop(context, _usernameController.text.trim())
                  : null,
              child: Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  color: _isValid ? const Color.fromARGB(255, 76, 160, 255) : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
