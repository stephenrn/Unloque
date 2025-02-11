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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String errorMessage = '';
  bool isLoading = false;
  bool isFormFilled = false; // Add this property

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
      print('isFormFilled: $isFormFilled'); // Debug print
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 53, 147, 255), Colors.white], // Gradient from blue to white
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30), // Add some space at the top
                Text(
                  'Unloque',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                SizedBox(height: 40), // Add some space between the title and the card
                Container(
                  width: MediaQuery.of(context).size.width * 0.93,
                  constraints: BoxConstraints(maxWidth: 400), // Make the card even longer
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, // Card background white
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[900]!, width: 1), // Grey outline
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // More visible shadow
                        blurRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 50,
                          color: Colors.grey[800], // Dark grey
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
                            widget.toggleView();
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
                        isOutlined: !isFormFilled, // Change this property
                        isEnabled: isFormFilled, // Add this property
                      ),
                      SizedBox(height: 0.1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[600], thickness: 1)), // Thicker divider
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5), // More padding
                              child: Text(
                                'Or',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[600], thickness: 1)), // Thicker divider
                          ],
                        ),
                      ),
                      SizedBox(height: 0.1),
                      GoogleButton(),
                      SizedBox(height: 10),
                    ],
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
