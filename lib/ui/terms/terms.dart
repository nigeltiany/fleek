import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:dating/ui/terms/content.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_html_css/simple_html_css.dart';

class TermsScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            pushReplacement(context, AuthScreen());
          },
        ),
        actions: [
          FlatButton.icon(
            icon: Icon(Icons.check, color: Colors.white),
            label: Text("Agree"),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setBool(TERMS_ACCEPTED, true);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              Center(
                child: Text("END USER LICENSE",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                  ),
                ),
              ),
              Center(
                child: Text("AGREEMENT",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text("Updated March 4th, 2021",
                style: TextStyle(
                  color: Colors.black
                ),
              ),
              HTML.toRichText(context, TERMS,
                defaultTextStyle: TextStyle(
                  decoration: TextDecoration.none
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}