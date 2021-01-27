import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:flutter/material.dart';

class AllSet extends StatelessWidget {

  final PageController pageController;

  const AllSet({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: isDarkMode(context) ? Colors.black : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Spacer(),
              _motive(),
              Spacer(),
              _nextScreenButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _motive () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Done!',
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12),
            Text('Go get them and remember to be respectful. ',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextScreenButton (BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Get them",
          onTap: () async {
            pushAndRemoveUntil(context, HomeScreen(), false);
          },
        ),
      ),
    );
  }

}
