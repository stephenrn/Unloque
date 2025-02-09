import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/components/my_textfield.dart';
import 'package:unloque/components/continueButton.dart';
import 'package:unloque/components/google_button.dart';
import 'home_page.dart';
import '../auth/login_or_register.dart';

class SignUpPage extends StatefulWidget {
  final Function toggleView;

  SignUpPage({super.key, required this.toggleView});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String errorMessage = '';
  bool isLoading = false;

  Future<void> signUp() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showErrorSnackbar('Please fill in all fields');
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      showErrorSnackbar('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create the user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Store the username in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      // If storing the username fails, delete the user
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 55,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Create an Account!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  widget.toggleView();
                                },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    MyTextfield(
                      controller: usernameController,
                      label: 'Username',
                      hint: 'Enter your username',
                      obscureText: false,
                    ),
                    const SizedBox(height: 17),
                    MyTextfield(
                      controller: emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 17),
                    MyTextfield(
                      controller: passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 17),
                    MyTextfield(
                      controller: confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      obscureText: true,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    MyButton(
                      onTap: signUp,
                      label: 'Continue',
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('or', style: TextStyle(color: Colors.grey[600])),
                          ),
                          Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GoogleButton(),
                  ],
                ),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
