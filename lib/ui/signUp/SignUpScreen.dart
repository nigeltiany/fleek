import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/FormInput.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/model/KeyPair.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecies/gecies.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();


  String username, email, mobile, password;
  LocationData signUpLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.white : Colors.black
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: formUI(),
        ),
      ),
    );
  }

  Widget formUI() {
    return new Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 24.0),
            child: Text('Create New Account',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        FormInput(
          type: TextInputType.name,
          textInputAction: TextInputAction.next,
          controller: _usernameController,
          label: "Username",
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        FormInput(
          type: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          controller: _emailController,
          label: "Email",
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        FormInput(
          type: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          controller: _passwordController,
          label: "Password",
          obscureText: true,
          onSubmitted: (password) => _signUp(),
        ),
        SizedBox(height: 32,),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0, left: 24.0),
            child: PrimaryButton(
              label: "SIGN UP",
              onTap: _signUp,
            )
          ),
        ),
      ],
    );
  }

  _signUp() async {
    showProgress(context, 'Creating new account...', false);

    try {

      UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.value.text.trim(),
        password: _passwordController.value.text.trim()
      );

      HttpsCallable createKeyPair = FirebaseFunctions.instance.httpsCallable('createKeyPair');
      createKeyPair.call<Map<String, dynamic>>().then((result) {
        if (!result.data.containsKey('PrivateKey') || !result.data.containsKey('PublicKey')) {
          throw KeyException("Authentications keys response is deformed and unexpected");
        } else if (result.data['PublicKey'].toString().isEmpty || result.data['PrivateKey'].toString().isEmpty) {
          throw KeyException("Authentications keys received are deformed");
        }
        context.read<KeyPair>().publicKeyBase64 = result.data['PublicKey'];
        context.read<KeyPair>().privateKeyBase64 = result.data['PrivateKey'];
        context.read<AppUser>().publicKey = result.data['PublicKey'];
        context.read<EncrypterState>().encrypter = (String message) async {
          return await Gecies.encrypt(result.data['PublicKey'], message);
        };
      }).catchError((e) {
        throw FirebaseFunctionsException(message: e);
      });
      await saveUserKeyPair(userID: result.user.uid, keyPair: context.read<KeyPair>());

      Navigator.of(context).pop(); // Close Dialog
      await goToNextScreenAfterAuth(context, result.user.uid);

    } catch (error) {
      Navigator.of(context).pop(); // Close Dialog
      print(error.toString());
      if (error is PlatformException) {
        error.code != 'ERROR_EMAIL_ALREADY_IN_USE'
          ? showAlertDialog(context, 'Failed', 'Couldn\'t sign up')
          : showAlertDialog(context, 'Failed', 'Email already in use, Please pick another email!');
      } else if (error is NoSuchMethodError) {
        print(error.stackTrace);
        print(error.hashCode);
        print(error.toString());
      } else if (error is FirebaseFunctionsException) {
        showAlertDialog(context, 'Failed', 'An error occurred when creating your account');
        HttpsCallable panicDeleteUser = FirebaseFunctions.instance.httpsCallable('panicDeleteUser');
        await panicDeleteUser.call();
      } else {
        print(error.toString());
      }
    }

  }

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

}