import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/SwipeCounterModel.dart';
import 'package:dating/store/Data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwipeThrottle extends StatefulWidget {
  @override
  _SwipeThrottleState createState() => _SwipeThrottleState();
}

class _SwipeThrottleState extends State<SwipeThrottle> {

  Timer timer;
  final StreamController<Duration> _timeStream = StreamController<Duration>.broadcast();
  double initialTimeFractionLeft;

  @override
  void initState() {
    super.initState();
    var data = context.read<FleekData>();

    data.addListener(() {
      if (data.maxHourlyCountExceeded) {
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelTimer();
    _timeStream.close();
  }

  void startTimer () {
    if (timer != null) {
      if (timer.isActive) return;
    }
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      _timeStream.add(_durationLeft(context.read<FleekData>().swipeCounter));
    });
  }

  void cancelTimer() {
    if (timer != null) {
      if (!timer.isActive) return;
    }
    (timer ?? Timer.periodic(Duration(days: 1), (_) => {})).cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FleekData>(
        builder: (BuildContext ctx, FleekData fleekData, _) {
          return Visibility(
            visible: fleekData.maxHourlyCountExceeded,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.333333),
                    child: Center(
                      child: StreamBuilder<Duration>(
                        initialData: _durationLeft(fleekData.swipeCounter),
                        stream: _timeStream.stream,
                        builder: (context, snapshot) {
                          var duration = snapshot.data;

                          if (duration.isNegative || duration.inSeconds == 0 || !fleekData.maxHourlyCountExceeded) {
                            cancelTimer();
                            Future.delayed(Duration(seconds: 0), () => fleekData.resetSwipeCounter());
                            return Container(width: 0, height: 0);
                          }

                          int hours = duration.inHours.remainder(24);
                          int minutes = duration.inMinutes.remainder(60);
                          int seconds = duration.inSeconds.remainder(60);
                          String hourString = hours == 1 ? "1 Hour" : "$hours Hours";
                          String minString = minutes == 1 ? "1 Minute" : "$minutes Minutes";
                          String secondString = seconds == 1 ? "1 Second" : "$seconds Seconds";

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Let's take a break",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                              Text("$hourString $minString $secondString", style: _timerStyle),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  TextStyle get _timerStyle {
    return const TextStyle(
      fontSize: 21,
      color: Color(COLOR_PRIMARY_DARK),
    );
  }

  Duration _durationLeft(SwipeCounter counter) {
    var createdAt = (counter.createdAt ?? Timestamp.now()).toDate();
    return Duration(hours: FleekData.HOURS_SWIPE_THROTTLE) - createdAt.difference(DateTime.now()).abs();
  }

}
