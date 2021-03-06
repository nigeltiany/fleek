import 'dart:async';

import 'package:dating/constants.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';


class AvatarWithCountDown extends StatefulWidget {

  final FleekMatch fleekMatch;

  const AvatarWithCountDown({
    Key key,
    @required this.fleekMatch,
  }) : super(key: key);

  @override
  _AvatarWithCountDownState createState() => _AvatarWithCountDownState(this.fleekMatch);

}

class _AvatarWithCountDownState extends State<AvatarWithCountDown> {

  double initialData;
  Timer timer;
  final StreamController<double> _timeStream = StreamController<double>.broadcast();

  final FleekMatch fleekMatch;

  _AvatarWithCountDownState(this.fleekMatch);

  @override
  void initState() {
    super.initState();
    initialData = _timeLeft(fleekMatch);
    if (initialData > 0) {
      timer = Timer.periodic(Duration(minutes: 1), (t) {
        _timeStream.add(_timeLeft(fleekMatch));
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    _timeStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (initialData <= 0) {
      return displayCircleImage(fleekMatch.match.profilePictureURL, 50, false);
    }

    return StreamBuilder<double>(
      initialData: initialData,
      stream: _timeStream.stream,
      builder: (context, snapshot) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 20,
              value: snapshot.data < 0 ? 0 : snapshot.data,
            ),
            displayCircleImage(fleekMatch.match.profilePictureURL, 50, false),
          ],
        );
      },
    );

  }

  double _timeLeft(FleekMatch match) {
    var createdAt = fleekMatch.createdAt.toDate();
    var now = DateTime.now();
    var exp = createdAt.add(MATCH_EXPIRATION);
    var diff = exp.difference(now);
    var divided = diff.inSeconds / MATCH_EXPIRATION.inSeconds;
    return divided;
  }

}
