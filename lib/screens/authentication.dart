
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';


class AuthenticationScreen extends StatefulWidget
{
  AuthenticationScreen({super.key});


  @override
  State<AuthenticationScreen> createState() {
    return _AuthenticationScreenState();
  }

}

class _AuthenticationScreenState extends State<AuthenticationScreen>
{

  bool _isLogin = true;
  bool _showPasswordReset = false;
  final _formKey = GlobalKey<FormState>();
  FirebaseAuth auth = FirebaseAuth.instance;
  String _email='';
  String _password='';
  int _age=0;
  String _phoneNumber='';
  String _fullName='';

  void _loginUser() async
  {
    FocusManager.instance.primaryFocus?.unfocus();
    if(_formKey.currentState!.validate())
    {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).clearSnackBars();
      try
      {
        final user = await auth.signInWithEmailAndPassword(email: _email, password: _password);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successful!")));
      }
      on FirebaseAuthException catch (error)
      {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Email or Password")));
        setState(() {
          _showPasswordReset=true;
        });
      }
    }
  }

  void _signUpUser() async
  {
    FocusManager.instance.primaryFocus?.unfocus();
    if(_formKey.currentState!.validate())
    {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).clearSnackBars();
      try
      {
        final user = await auth.createUserWithEmailAndPassword(email: _email, password: _password);
        await FirebaseAuth.instance.currentUser!.sendEmailVerification();
        DatabaseReference ref = FirebaseDatabase.instance.ref("${FirebaseAuth.instance.currentUser!.uid}/profile");
        await ref.set({
          "Full-Name": _fullName,
          "Email": _email,
          "Age": _age,
          "Phone-Number": _phoneNumber,
         }
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signup Successful, Verification Link Sent.")));
      }
      on FirebaseAuthException catch (error)
      {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message!)));
      }
      setState(() {
        _isLogin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: const Color.fromRGBO(26, 104, 155, 1),
        body: Center(
          child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        bottom: 50
                        , left: 32, right: 20, top: 30),
                    width: 450,
                    child: Image.asset("lib/assets/images/logo.png"),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 14, left: 14, bottom: 14, top: 7),
                    child: Card(
                      elevation: 7,
                      color: Colors.white.withOpacity(0.8),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Padding(
                              padding: const EdgeInsets.only(left: 17,right: 17, top: 7, bottom: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if(_isLogin) TextFormField(                                                                // form fields for login
                                    decoration: const InputDecoration(label: Text("Registered Email"), icon: Icon(Icons.mail_outline_rounded)),
                                    keyboardType: TextInputType.emailAddress,
                                    onSaved: (newValue) {
                                      _email = newValue!;
                                    },
                                    validator: (value) {
                                      if(value == null || value.toString().trim().isEmpty || !(value.toString().contains("@")) || value.toString().length<8 || !(value.toString().contains(".")))
                                      {
                                        return "Invalid Email Address";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 5,),
                                  if(_isLogin) TextFormField(
                                    decoration: const InputDecoration(label: Text("Password"),icon: Icon(Icons.password_rounded)),
                                    obscureText: true,
                                    keyboardType: TextInputType.visiblePassword,
                                    onSaved: (newValue) {
                                      _password = newValue!;
                                    },
                                    validator: (value) {
                                      if(value == null || value.toString().isEmpty || value.toString().trim().length<6)
                                      {
                                        return "Password must be 6 character long";
                                      }
                                      return null;
                                    },

                                  ),
                                  if(!_isLogin) TextFormField(
                                      decoration: const InputDecoration(label: Text("Full Name"),icon: Icon(Icons.account_box_rounded)),
                                      keyboardType: TextInputType.name,
                                      onSaved: (newValue) {
                                        _fullName = newValue!;
                                      },
                                      validator: (value) {
                                        if(value == null || value.toString().isEmpty || !value.toString().trim().contains(" "))
                                        {
                                          return "Please enter valid full name";
                                        }
                                        return null;
                                      }
                                  ),                                                              // form fields for signup
                                  if(!_isLogin) TextFormField(
                                      decoration: const InputDecoration(label: Text("Contact Number"), prefix: Text("+91 "), icon: Icon(Icons.phone)),
                                      keyboardType: TextInputType.number,
                                      onSaved: (newValue) {
                                        _phoneNumber = newValue!;
                                      },
                                      validator: (value) {
                                        if(value == null || value.toString().isEmpty || value.toString().trim().length<10)
                                        {
                                          return "Please enter valid contact number";
                                        }
                                        return null;
                                      }
                                  ),
                                  if(!_isLogin) TextFormField(
                                      decoration: const InputDecoration(label: Text("Age"),icon: Icon(Icons.numbers_rounded)),
                                      keyboardType: TextInputType.number,
                                      onSaved: (newValue) {
                                        _age = int.parse(newValue!);
                                      },
                                      validator: (value) {
                                        if(value == null || value.toString().isEmpty || int.parse(value) <= 0 || int.parse(value) >=100)
                                        {
                                          return "Please enter valid Age";
                                        }
                                        return null;
                                      }
                                  ),
                                  if(!_isLogin) TextFormField(                                                                // form fields for login
                                    decoration: const InputDecoration(label: Text("Email"),icon: Icon(Icons.mail_outline_rounded)),
                                    keyboardType: TextInputType.emailAddress,
                                    onSaved: (newValue) {
                                      _email = newValue!;
                                    },
                                    validator: (value) {
                                      if(value == null || value.toString().trim().isEmpty || !(value.toString().contains("@")) || value.toString().length<8 || !(value.toString().contains(".")))
                                      {
                                        return "Invalid Email Address";
                                      }
                                      return null;
                                    },
                                  ),
                                  if(!_isLogin) TextFormField(
                                    decoration: const InputDecoration(label: Text("Password"),icon: Icon(Icons.password_rounded)),
                                    keyboardType: TextInputType.visiblePassword,
                                    obscureText: true,
                                    onSaved: (newValue) {
                                      _password = newValue!;
                                    },
                                    validator: (value) {
                                      if(value == null || value.toString().isEmpty || value.toString().trim().length<6)
                                      {
                                        return "Password must be 6 character long";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30,),
                                  ElevatedButton(
                                      onPressed: _isLogin ? _loginUser : _signUpUser,
                                      style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Color.fromRGBO(255, 29, 38,0.9))),
                                      child: Text(_isLogin ? "Login":"Signup", style: const TextStyle(color: Colors.white
                                        ,))
                                  ),
                                  TextButton(
                                    onPressed: (){
                                      setState(() {
                                        _formKey.currentState!.reset();
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        _isLogin = !_isLogin;
                                      });
                                    },
                                    child: Text(_isLogin ? "Create Account":"Already Have Account", style: const TextStyle(color: Color.fromRGBO(26, 104, 155, 1))),
                                  ),
                                  if (_isLogin && _showPasswordReset) TextButton(
                                    onPressed: (){
                                      FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Reset Link Sent via Email")));
                                    },
                                    child: const Text("Reset Password", style: TextStyle(color: Color.fromRGBO(26, 104, 155, 1))),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
          ),
        )

    );
  }
}