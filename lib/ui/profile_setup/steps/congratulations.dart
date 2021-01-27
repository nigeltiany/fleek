import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:flutter/material.dart';

class Congrats extends StatelessWidget {

  final PageController pageController;

  const Congrats({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _title(),
              _niceImage(),
              _nextScreenButton()
            ],
          ),
      ),
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
            Text('Congratulations on getting verified',
              style: TextStyle(
                  color: Color(COLOR_PRIMARY),
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _niceImage () {
    return FlutterLogo(size: 236,);
  }

  Widget _nextScreenButton () {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Get Started",
          onTap: () async {
            await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
          },
        ),
      ),
    );
  }

}