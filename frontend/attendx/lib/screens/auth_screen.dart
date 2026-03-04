import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Authenticator extends StatefulWidget {
  const Authenticator({super.key});

  @override
  State<Authenticator> createState() => _AuthenticatorState();
}

class _AuthenticatorState extends State<Authenticator> {

  String _currentForm = "login";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> loginUser() async {

    var url = Uri.parse("http://127.0.0.1:5000/login");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text,
        "password": _passwordController.text
      }),
    );

    print(response.body);
  }


  Future<void> registerUser() async {

    var url = Uri.parse("http://127.0.0.1:5000/register");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text,
        "username": _usernameController.text,
        "password": _passwordController.text
      }),
    );

    print(response.body);
  }


  Future<void> forgotPassword() async {

    var url = Uri.parse("http://127.0.0.1:5000/forgot-password");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text
      }),
    );

    print(response.body);
  }



  Widget buildLogin() {
    return Column(
      children: [

        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 25),

        ElevatedButton(
          onPressed: loginUser,
          child: const Text("Login"),
        ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () {
            setState(() {
              _currentForm = "forgot";
            });
          },
          child: const Text("Forgot Password"),
        ),

        TextButton(
          onPressed: () {
            setState(() {
              _currentForm = "register";
            });
          },
          child: const Text("Create Account"),
        )
      ],
    );
  }


  Widget buildRegister() {
    return Column(
      children: [

        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: "Username",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 25),

        ElevatedButton(
          onPressed: registerUser,
          child: const Text("Register"),
        ),

        TextButton(
          onPressed: () {
            setState(() {
              _currentForm = "login";
            });
          },
          child: const Text("Back to Login"),
        )
      ],
    );
  }


  Widget buildForgot() {
    return Column(
      children: [

        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 25),

        ElevatedButton(
          onPressed: forgotPassword,
          child: const Text("Reset Password"),
        ),

        TextButton(
          onPressed: () {
            setState(() {
              _currentForm = "login";
            });
          },
          child: const Text("Back to Login"),
        )
      ],
    );
  }



  Widget getForm() {

    if (_currentForm == "login") {
      return buildLogin();
    }

    if (_currentForm == "register") {
      return buildRegister();
    }

    return buildForgot();
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff0f172a),

      body: Center(

        child: Container(

          width: 400,
          padding: const EdgeInsets.all(30),

          decoration: BoxDecoration(
            color: const Color(0xff1e293b),
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Text(
                "AttendX",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              getForm()

            ],
          ),
        ),
      ),
    );
  }
}