import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';


class ConversationTimer extends StatefulWidget {

  final Timestamp createdAt;

  const ConversationTimer({
    Key key,
    @required this.createdAt,
  }) : super(key: key);

  @override
  _ConversationTimerState createState() => _ConversationTimerState(this.createdAt);

}

class _ConversationTimerState extends State<ConversationTimer> {

  double initialData;
  Timer timer;
  final StreamController<double> _timeStream = StreamController<double>.broadcast();

  final Timestamp createdAt;

  _ConversationTimerState(this.createdAt);

  @override
  void initState() {
    super.initState();
    var time = createdAt;
    if (time == null) {
      time = Timestamp.now();
    }
    initialData = _timeLeft(time);
    if (initialData > 0) {
      timer = Timer.periodic(Duration(minutes: 1), (t) {
        _timeStream.add(_timeLeft(time));
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

    return StreamBuilder<double>(
      initialData: initialData,
      stream: _timeStream.stream,
      builder: (context, snapshot) {
        return CircularProgressIndicator(
          value: snapshot.data < 0 ? 0 : snapshot.data,
        );
      },
    );

  }

  double _timeLeft(Timestamp t) {
    var createdAt = t.toDate();
    var now = DateTime.now();
    var exp = createdAt.add(CONVERSATION_EXPIRATION);
    var diff = exp.difference(now);
    var divided = diff.inSeconds / CONVERSATION_EXPIRATION.inSeconds;
    return divided;
  }

}
