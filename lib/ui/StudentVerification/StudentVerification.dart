import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/model/ProfileSetup.dart';
import 'package:dating/model/StudentStatus.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/StudentVerification/EmailSent.dart';
import 'package:dating/ui/profile_setup/ProfileSetupScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentVerificationScreen extends StatefulWidget {

  StudentVerificationScreen({
    Key key,
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

  CollectionReference reference;

  @override
  void initState() {
    super.initState();
    _schoolController.text = "North Carolina A&T University";

    reference = FirebaseFirestore.instance.collection(VERIFICATIONS);
    _listenToFirebaseChanges();

  }

  _listenToFirebaseChanges() async {
    var _doc = reference.doc(FirebaseAuth.instance.currentUser.uid);
    var getSnap = await _doc.get();
    if (getSnap == null || !getSnap.exists) {
      return;
    }
    _doc.snapshots().listen((querySnapshot) {
      var status = StudentStatus.fromJson(querySnapshot.data());
      if (status.verified) {
        push(context, ProfileSetupScreen(step: ProfileSetupStep.NOT_STARTED,));
      } else if (status.emailedAt != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return EmailSent(status: status, resendEmail: this._sendData);
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
        child: PrimaryButton(
          label: "Verify",
          onTap: () async {
            await _sendData();
          },
        ),
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

    HttpsCallable func = FirebaseFunctions.instance.httpsCallable('sendStudentVerificationEmail');
    await func.call(<String, String>{
      "first_name": _firstNameController.value.text,
      "last_name": _lastNameController.value.text,
      "student_email": _emailController.value.text + emailSuffix,
      "school_code": "002905" // A&T
    }).then((result) {
      Navigator.of(context).pop();
      _listenToFirebaseChanges();
    }).catchError((e) {
      Navigator.of(context).pop();
      var error = (e as FirebaseFunctionsException);
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

}
