import 'dart:async';

import 'package:dating/constants.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:flutter/material.dart';

import 'AvatarWithCountDown.dart';

class MatchCard extends StatefulWidget {

  final FleekMatch fleekMatch;
  final VoidCallback expired;

  const MatchCard({Key key,
    @required this.fleekMatch,
    this.expired,
  }) : super(key: key);

  @override
  _MatchCardState createState() => _MatchCardState(this.fleekMatch);

}

class _MatchCardState extends State<MatchCard> {

  Timer timer;
  double initialTimeFractionLeft;

  final StreamController<double> _timeStream = StreamController<double>.broadcast();
  final FleekMatch fleekMatch;


  _MatchCardState(this.fleekMatch);

  @override
  void initState() {
    super.initState();
    initialTimeFractionLeft = _timeFractionLeft(fleekMatch);

    _timeStream.stream.listen((_) {
      if (_durationLeft(fleekMatch).inSeconds <= 60) {
        cancelTimer();
        timer = Timer.periodic(Duration(seconds: 3), (t) {
          if (_timeFractionLeft(fleekMatch) > 0) {
            _timeStream.add(_timeFractionLeft(fleekMatch));
          }
        });
      }
    });

    if (initialTimeFractionLeft > 0) {
      _timeStream.add(_timeFractionLeft(fleekMatch));
      timer = Timer.periodic(Duration(minutes: 1), (t) {
        _timeStream.add(_timeFractionLeft(fleekMatch));
      });
    }

  }

  void cancelTimer() {
    (timer ?? Timer.periodic(Duration(days: 1), (_) => {})).cancel();
  }

  @override
  void dispose() {
    cancelTimer();
    timer = null;
    _timeStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (initialTimeFractionLeft <= 0) {
      cancelTimer();
      widget.expired?.call();
      return Container();
    }

    return StreamBuilder<double>(
      initialData: initialTimeFractionLeft,
      stream: _timeStream.stream,
      builder: (context, snapshot) {
        if (snapshot.data <= 0) {
          cancelTimer();
          widget.expired?.call();
          return Container();
        }
        return InkWell(
          onLongPress: () async => { await _onMatchLongPress() },
          onTap: () async {
            push(context, ChatScreen(identifiableUser: fleekMatch.match));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AvatarWithCountDown(fleekMatch: fleekMatch),
                Expanded(
                  child: Container(
                    width: 76,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                      child: Text('${fleekMatch.match.userName}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  double _timeFractionLeft(FleekMatch match) {
    return _durationLeft(match).inSeconds / MATCH_EXPIRATION.inSeconds;
  }

  Duration _durationLeft(FleekMatch match) {
    var createdAt = fleekMatch.createdAt.toDate();
    return createdAt.add(MATCH_EXPIRATION).difference(DateTime.now());
  }

  Widget _timeCountDown (StreamController<Duration> streamController) {
    const style = const TextStyle(
      fontSize: 18,
    );
    const Widget noTimeLeft = const Text("00:00:00", style: style);
    if (_timeFractionLeft(fleekMatch) > 0) {
      return StreamBuilder<Duration>(
        initialData: _durationLeft(fleekMatch),
        stream: streamController.stream,
        builder: (context, snapshot) {
          var data = snapshot.data;
          if (data.inSeconds <= 0) {
            return noTimeLeft;
          }
          int days = data.inDays.remainder(365.25).floor();
          int hours = data.inHours.remainder(24);
          int minutes = data.inMinutes.remainder(60);
          int seconds = data.inSeconds.remainder(60);
          String dayString = days == 1 ? "$days Day" : "$days Days";
          String hourString = hours == 1 ? "$hours Hour" : "$hours Hours";
          String minString = minutes == 1 ? "$minutes Minute" : "$minutes Minutes";
          String secondString = seconds == 1 ? "$seconds Second" : "$seconds Seconds";
          return Text("$dayString $hourString $minString $secondString".trim(), style: style);
        },
      );
    }
    return noTimeLeft;
  }

  _onMatchLongPress () async {

    final StreamController<Duration> _dialogTimeStream = StreamController<Duration>.broadcast();
    var dialogTimer = Timer.periodic(Duration(seconds: 1), (t) {
      _dialogTimeStream.add(_durationLeft(fleekMatch));
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          titlePadding: EdgeInsets.symmetric(horizontal: 8),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          title: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 64,
            leading: Center(
              child: AvatarWithCountDown(fleekMatch: fleekMatch),
            ),
            centerTitle: false,
            title: Text("${fleekMatch.match.userName}",
              style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Text("Time Left",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: _timeCountDown(_dialogTimeStream)),
            ),
          ]
        );
      },
    );

    dialogTimer.cancel();
    _dialogTimeStream.close();

  }

}
