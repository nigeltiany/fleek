import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BioSetup extends StatefulWidget {

  final PageController pageController;

  const BioSetup({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  _BioSetupState createState() => _BioSetupState(pageController);

}

class _BioSetupState extends State<BioSetup> {

  final PageController pageController;

  TextEditingController _bioController = TextEditingController();
  TextEditingController _DOB_Controller = TextEditingController();
  DateTime dob;

  _BioSetupState(this.pageController);

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
              _nextScreenButton()
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
            Text('Bio',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('Say something about yourself'),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _formElements() {
    return [
      FormInput(
        type: TextInputType.datetime,
        textInputAction: TextInputAction.next,
        controller: _DOB_Controller,
        label: "Birth Date",
        readOnly: true,
        onTap: () async {
          var now = DateTime.now();
          var eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
          dob = await showDatePicker(
            context: context,
            initialDate: eighteenYearsAgo,
            firstDate: now.subtract(Duration(days: 365 * 35)),
            lastDate: eighteenYearsAgo,
          );
          if (dob != null) {
            _DOB_Controller.text = dob.toString().split(" ")[0];
            setState(() {});
          }
        },
      ),
      Container(
        height: 200.0,
        child: FormInput(
          type: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          controller: _bioController,
          label: "Bio",
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ),
    ];
  }

  Widget _nextScreenButton () {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Continue",
          onTap: dob == null ? null : () async {
            var user = context.read<AppUser>();
            user.bio = _bioController.text;
            user.birthDate = Timestamp.fromDate(dob);

            await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
          },
        ),
      ),
    );
  }

}