import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/model/ProfileSetup.dart';
import 'package:dating/model/StudentStatus.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/profile_setup/ProfileSetupScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentVerificationScreen extends StatefulWidget {

  final String userID;

  StudentVerificationScreen({
    Key key,
    @required this.userID
  }) : super(key: key);

  @override
  _StudentVerificationScreenState createState() => _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _schoolController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _schoolController.text = "North Carolina A&T University";

    CollectionReference reference = FirebaseFirestore.instance.collection('student-verification');
    reference.doc(FirebaseAuth.instance.currentUser.uid).snapshots().listen((querySnapshot) {
      if (StudentStatus.fromJson(querySnapshot.data()).verified) {
        pushAndRemoveUntil(context, ProfileSetupScreen(
          userID: FirebaseAuth.instance.currentUser.uid,
          step: ProfileSetupStep.NOT_STARTED,
        ), false);
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
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
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
      FormInput(
        type: TextInputType.name,
        textInputAction: TextInputAction.next,
        controller: _lastNameController,
        label: "Last Name",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
      FormInput(
        type: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        controller: _emailController,
        label: "School Email",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
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

  _sendData () async {
    HttpsCallable func = FirebaseFunctions.instance.httpsCallable('verifyStudentStatus');
    func.call(<String, String>{
      "firstname": _firstNameController.value.text,
      "lastname": _lastNameController.value.text,
      "student_email": _emailController.value.text,
      "school_code": "002905" // A&T
    }).then((result) {
     print(result.data);
    }).catchError((e) {
      print(e);
    });

  }

}
