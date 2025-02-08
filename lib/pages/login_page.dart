import 'package:flutter/material.dart';
import 'package:unloque/components/signinButton.dart';
import '../components/my_textfield.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  //text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                //Sign in txt
                //Welcome Back
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                            fontSize: 55,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold),
                      ),
                      Text('Welcome Back!',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[800])),
                      Row(
                        children: [
                          Text(
                            'Are you a new User? ',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[800]),
                          ),
                          GestureDetector(
                            onTap: () {
                              print("Sign up"); //TO SIGN UP PAGE
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 50),
                //Username txtfield
                MyTextfield(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  obscureText: false,
                ),

                const SizedBox(height: 17),
                //Password txtfield
                MyTextfield(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                ),

                const SizedBox(height: 10),
                //Forgot Password
                Center(
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 200),
            Column(
              children: [
                //Continue button
                MyButton(),
                const SizedBox(height: 10),
                // Divider with "or"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Google button
                GoogleButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton(
        onPressed: () {
          print("Continue with Google");
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.black),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Same border radius as MyButton
          ),
        ),
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
