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

  TextEditingController _userNameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _bioController = TextEditingController();

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
        type: TextInputType.name,
        textInputAction: TextInputAction.next,
        controller: _userNameController,
        label: "Username",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
      FormInput(
        type: TextInputType.number,
        textInputAction: TextInputAction.next,
        controller: _ageController,
        label: "Age",
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
          onTap: () async {
            var user = context.read<AppUser>();
            user.userName = _userNameController.text;
            user.age = int.parse(_ageController.text.replaceAll(",", "").replaceAll(".", ""));
            user.bio = _bioController.text;

            await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
          },
        ),
      ),
    );
  }

}