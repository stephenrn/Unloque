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
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[800])),
                    Row(
                      children: [
                        Text(
                          'Are you a new User? ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
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

              const SizedBox(height: 17),
              //Continue button
              MyButton()
            ],
          ),
        ));
  }
}
