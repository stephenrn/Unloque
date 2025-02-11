import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unloque/components/continueButton.dart';
import 'package:unloque/components/google_button.dart';
import '../components/my_textfield.dart';
import 'home_page.dart';
import 'forget_password_page.dart';

class SignInCard extends StatefulWidget {
  final VoidCallback onBack;

  SignInCard({super.key, required this.onBack});

  @override
  _SignInCardState createState() => _SignInCardState();
}

class _SignInCardState extends State<SignInCard> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool isFormFilled = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_checkFormFilled);
    passwordController.addListener(_checkFormFilled);
  }

  void _checkFormFilled() {
    setState(() {
      isFormFilled = emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.93,
      constraints: BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[900]!, width: 1),
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
          SizedBox(height: 10),
          Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 50,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Welcome Back! Sign in to continue.',
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
            controller: passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: true,
          ),
          SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgetPasswordPage()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                      text: 'Are you a new User? ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'Sign Up',
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
            onTap: signIn,
            label: 'Sign In',
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
    );
  }
}
