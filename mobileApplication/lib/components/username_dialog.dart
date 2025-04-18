import 'package:flutter/material.dart';

class UsernameDialog extends StatefulWidget {
  @override
  _UsernameDialogState createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      _validateUsername(_usernameController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

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
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Username',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                hintStyle: TextStyle(color: Colors.grey[500]),
                labelStyle: TextStyle(color: Colors.grey[300]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isValid
                  ? () =>
                      Navigator.pop(context, _usernameController.text.trim())
                  : null,
              child: Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  color: _isValid ? Colors.blue[300] : Colors.grey[700],
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
