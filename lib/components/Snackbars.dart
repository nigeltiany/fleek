import 'dart:ui';

import 'package:dating/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rounded_progress_bar/flutter_rounded_progress_bar.dart';
import 'package:flutter_rounded_progress_bar/rounded_progress_bar_style.dart';


enum FileType {
  IMAGE,
  AUDIO,
}

OverlayEntry showEncryptingSnackBar(BuildContext context, FileType fileType) {
  String desc = "File";
  switch (fileType) {
    case FileType.IMAGE:
      desc = "Image";
      break;
    case FileType.AUDIO:
      desc = "Audio Message";
      break;
  }
  var customSnackBar = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 56,
          child: Card(
            elevation: 2,
            shape: StadiumBorder(
              side: BorderSide(
                color: Color(COLOR_PRIMARY_DARK),
                width: 2.0,
              ),
            ),
            color: Color(0xFF323232).withOpacity(0.86),
            child: Container(
              height: 48,
              child: Center(
                child: Text('Encrypting $desc',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
  );

  Overlay.of(context).insert(customSnackBar);

  return customSnackBar;
}

class OverlayWithUpdater {
  final OverlayEntry overlayEntry;
  final Function(TaskSnapshot event) updatedCallback;
  OverlayWithUpdater(this.overlayEntry, this.updatedCallback);
}

OverlayWithUpdater showUploadingSnackBar(BuildContext context) {

  var progressBar = _MultiMediaProgressBar();

  var customSnackBar = OverlayEntry(
    builder: (BuildContext context) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: 56,
        child: progressBar,
      );
    }
  );

  Overlay.of(context).insert(customSnackBar);

  return OverlayWithUpdater(customSnackBar, progressBar.updateFunction);
}

class _MultiMediaProgressBar extends StatefulWidget {

  _MultiMediaProgressBar({
    Key key,
  }) : super(key: key);

  final __MultiMediaProgressBarState _widget = __MultiMediaProgressBarState();

  void Function(TaskSnapshot event) get updateFunction => _widget.progressUpdated;

  @override
  __MultiMediaProgressBarState createState() => _widget;

}

class __MultiMediaProgressBarState extends State<_MultiMediaProgressBar> {

  double percent = 0;

  @override
  void initState() {
    super.initState();
  }

  void progressUpdated(TaskSnapshot event) {
    double p = (event.bytesTransferred.toDouble() / event.totalBytes.toDouble()) * 100;
    if (mounted) {
      setState(() {
        percent = p;
      });
    } else {
      percent = p;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoundedProgressBar(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      style: RoundedProgressBarStyle(
        borderWidth: 2,
        widthShadow: 0,
        colorBorder: Color(COLOR_PRIMARY_DARK),
        backgroundProgress: Color(0xFF323232).withOpacity(0.86),
        colorProgress: Color(COLOR_PRIMARY),
        colorProgressDark: Color(COLOR_PRIMARY_DARK),
      ),
      childCenter: Text("${percent.toStringAsFixed(1)} %",
        style: TextStyle(
          decoration: TextDecoration.none,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      percent: percent,
    );
  }

}
