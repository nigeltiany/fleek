import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/model/ProfileSetup.dart';
import 'package:dating/model/StudentStatus.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/StudentVerification/EmailSent.dart';
import 'package:dating/ui/profile_setup/ProfileSetupScreen.dart';
import 'package:dating/ui/signUp/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String VERIFICATION_ID_KEY = "STUDENT_VERIFICATION_ID";

class SignUpInfo {
  final String username;
  final String email;
  final String password;

  SignUpInfo({ this.username, this.email, this.password });
}

class StudentVerificationScreen extends StatefulWidget {

  final SignUpInfo signUpInfo;

  StudentVerificationScreen({
    Key key,
    this.signUpInfo, // NOT REQUIRED
  }) : super(key: key);

  @override
  _StudentVerificationScreenState createState() => _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {

  String firstNameError, lastNameError, emailError;

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _schoolController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  String emailSuffix = "@aggies.ncat.edu";

  double _backOffExponent = 1;
  DateTime _backOffEndsAt;
  Timer _backOffTimer;
  final StreamController<Duration> _backOffStream = StreamController<Duration>.broadcast();

  SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    sharedPreferences = context.read<SharedPreferences>();
    _schoolController.text = "North Carolina A&T University";

    if (sharedPreferences.containsKey(VERIFICATION_ID_KEY)) {
      var args = sharedPreferences.getString(VERIFICATION_ID_KEY).split("::");
      if (args.length < 2) return;
      _listenToFirebaseChanges(args[0], args[1]);
    }

  }

  _listenToFirebaseChanges(String verificationID, String studentEmail) async {
    var _doc = FirebaseFirestore.instance.collection(VERIFICATIONS_V2).doc(verificationID);
    var getSnap = await _doc.get();
    if (getSnap == null || !getSnap.exists) {
      return;
    }
    _doc.snapshots().listen((querySnapshot) async {
      var status = StudentStatus.fromJson(querySnapshot.data());
      if (status.verified) {
        sharedPreferences.remove(VERIFICATION_ID_KEY);
        bool success = await signUp(
          context: context,
          user: context.read<AppUser>(),
          keyPair: context.read<KeyPair>(),
          encrypter: context.read<EncrypterState>(),
          username: widget.signUpInfo.username,
          email: widget.signUpInfo.email,
          password: widget.signUpInfo.password,
        );
        if (!success) return;

        await FireStoreUtils.updateUserPrivateDetails(
          UserPrivateDetails(
            userID: FirebaseAuth.instance.currentUser.uid,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: FirebaseAuth.instance.currentUser.email,
            studentEmail: _emailController.text,
            verificationID: verificationID,
            verified: true,
          ),
        );

        push(context, ProfileSetupScreen(step: ProfileSetupStep.NOT_STARTED));

      } else if (status.emailedAt != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return EmailSent(status: status, resendEmail: this._sendData, studentEmail: studentEmail);
          }
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _title(),
              ..._formElements(),
              SizedBox(height: 32),
              _submitButton()
            ],
          ),
        ),
      )
    );
  }

  Widget _title () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enrollment Verification',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('Confirm you student status by entering your official enrollment details. This information will NOT be shown on the app.'),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _formElements() {
    return [
      FormInput(
        type: TextInputType.name,
        textInputAction: TextInputAction.next,
        controller: _firstNameController,
        label: "First Name",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
      _showError(firstNameError),
      FormInput(
        type: TextInputType.name,
        textInputAction: TextInputAction.next,
        controller: _lastNameController,
        label: "Last Name",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
      _showError(lastNameError),
      FormInput(
        type: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        controller: _emailController,
        label: "School Email",
        suffix: Text("@aggies.ncat.edu"),
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
      _showError(emailError),
      FormInput(
        type: TextInputType.name,
        textInputAction: TextInputAction.send,
        controller: _schoolController,
        label: "School",
        readOnly: true,
        onTap: () async {
          //await _showSchoolSelectorBottomSheet();
        },
      )
    ];
  }

  Widget _submitButton () {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: SizedBox(
        width: double.infinity,
        child: StreamBuilder<Duration>(
          initialData: Duration(seconds: 0),
          stream: _backOffStream.stream,
          builder: (BuildContext ctx, AsyncSnapshot<Duration> snapshot) {
            if (snapshot.data.isNegative || snapshot.data.inSeconds == 0) {
              return PrimaryButton(
                label: "Verify",
                onTap: () async {
                  await _sendData();
                },
              );
            }
            return PrimaryButton(
              label: "${snapshot.data.inSeconds} s",
            );
          },
        )
      ),
    );
  }

  Future _showSchoolSelectorBottomSheet () {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.green,
        );
      }
    );
  }

  Widget _showError (String errorString) {
    if (errorString != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: Text(errorString, style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    return Container();
  }

  bool _hasValidityErrors() {

    bool validFirstname = _firstNameController.value.text.trim().isNotEmpty;
    if(!validFirstname) {
      firstNameError = "First name cannot be empty";
    } else {
      firstNameError = null;
    }

    bool validLastName = _lastNameController.value.text.trim().isNotEmpty;
    if(!validLastName) {
      lastNameError = "Last name cannot be empty";
    } else {
      lastNameError = null;
    }

    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_emailController.value.text + emailSuffix);
    if (!emailValid) {
      emailError = "Invalid Email Address";
    } else {
      emailError = null;
    }

    setState(() {});
    return !validFirstname || !validLastName || !emailValid;

  }

  _sendData () async {

    if (_hasValidityErrors()) {
      return;
    }

    showProgress(context, 'Sending email', false);

    var studentEmailAddress = _emailController.value.text + emailSuffix;

    HttpsCallable func = FirebaseFunctions.instance.httpsCallable('sendStudentVerificationEmailV2');
    await func.call(<String, String>{
      "first_name": _firstNameController.value.text,
      "last_name": _lastNameController.value.text,
      "student_email": studentEmailAddress,
      "school_code": "002905" // A&T
    }).then((result) {
      Navigator.of(context).pop();
      sharedPreferences.setString(VERIFICATION_ID_KEY, "${result.data["verification_id"]}::$studentEmailAddress");
      _listenToFirebaseChanges(result.data["verification_id"], studentEmailAddress);
    }).catchError((e) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      var error = (e as FirebaseFunctionsException);

      if (error.code == "failed-precondition") {
        _startBackoffTimer();
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Email not sent"),
            content: Text(error.message),
          );
        },
      );
    });

  }

  _startBackoffTimer () {
    _backOffExponent += 0.67;
    if (_backOffTimer != null && _backOffTimer.isActive) {
      _backOffEndsAt = _backOffEndsAt.add(Duration(seconds: pow(e, _backOffExponent).ceil()));
    } else {
      _backOffEndsAt = DateTime.now().add(Duration(seconds: pow(e, _backOffExponent).ceil()));
    }
    _backOffTimer = Timer.periodic(Duration(seconds: 1), (_) {
      var diff = _backOffEndsAt.difference(DateTime.now());
      _backOffStream.add(diff);
      if (diff.inSeconds <= 0) {
        _backOffTimer.cancel();
      }
    });
  }

}
