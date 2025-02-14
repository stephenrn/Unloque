import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/components/my_textfield.dart';
import 'package:unloque/components/continueButton.dart';
import 'package:unloque/components/google_button.dart';
import 'home_page.dart';

class SignUpCard extends StatefulWidget {
  final VoidCallback onBack;

  SignUpCard({super.key, required this.onBack});

  @override
  _SignUpCardState createState() => _SignUpCardState();
}

class _SignUpCardState extends State<SignUpCard> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool isFormFilled = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_checkFormFilled);
    usernameController.addListener(_checkFormFilled);
    passwordController.addListener(_checkFormFilled);
  }

  void _checkFormFilled() {
    setState(() {
      isFormFilled = emailController.text.isNotEmpty &&
                     usernameController.text.isNotEmpty &&
                     passwordController.text.isNotEmpty;
    });
  }

  Future<void> signUp() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      showErrorSnackbar(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.93,
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.only(left:24, right: 24, bottom: 24, top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: widget.onBack,
            ),
            Text(
              'Sign Up',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 50,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ready to improve your well-being? Create an account and find everything you need in one place to support your needs.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
            ),
            SizedBox(height: 30),
            MyTextfield(
              controller: emailController,
              label: 'Email',
              hint: 'Enter your email',
              obscureText: false,
            ),
            SizedBox(height: 20),
            MyTextfield(
              controller: usernameController,
              label: 'Username',
              hint: 'Enter your name',
              obscureText: false,
            ),
            SizedBox(height: 20),
            MyTextfield(
              controller: passwordController,
              label: 'Password',
              hint: 'Create new password',
              obscureText: true,
            ),
            SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: () {
                  widget.onBack();
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF007AFF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            MyButton(
              onTap: signUp,
              label: 'Sign Up',
              isLoading: isLoading,
              isOutlined: !isFormFilled,
              isEnabled: isFormFilled,
            ),
            SizedBox(height: 0.1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[600], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      'Or',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[600], thickness: 1)),
                ],
              ),
            ),
            SizedBox(height: 0.1),
            GoogleButton(),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
