import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/components/ConversationTimer.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ConversationTile extends StatefulWidget {

  final ConversationModel conversationModel;
  final VoidCallback expired;
  final bool canExpire;

  const ConversationTile({
    Key key,
    @required this.conversationModel,
    this.expired,
    this.canExpire = false
  }) : super(key: key);

  @override
  _ConversationTileState createState() => _ConversationTileState(this.conversationModel);

}

class _ConversationTileState extends State<ConversationTile> {


  Timer timer;
  double initialTimeFractionLeft;
  AppUser currentUser;
  ConversationData conversationState;

  final ConversationModel conversationModel;
  final StreamController<double> _timeStream = StreamController<double>.broadcast();

  _ConversationTileState(this.conversationModel);

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    conversationState = context.read<ConversationData>();

    initialTimeFractionLeft = _timeFractionLeft(conversationModel);

    _timeStream.stream.listen((_) {
      if (_durationLeft(conversationModel).inSeconds <= 60) {
        cancelTimer();
        timer = Timer.periodic(Duration(seconds: 3), (t) {
          if (_timeFractionLeft(conversationModel) > 0) {
            _timeStream.add(_timeFractionLeft(conversationModel));
          }
        });
      }
    });

    if (initialTimeFractionLeft > 0 && widget.canExpire) {
      _timeStream.add(_timeFractionLeft(conversationModel));
      timer = Timer.periodic(Duration(minutes: 1), (t) {
        _timeStream.add(_timeFractionLeft(conversationModel));
      });
    }
  }

  double _timeFractionLeft(ConversationModel model) {
    return _durationLeft(model).inSeconds / CONVERSATION_EXPIRATION.inSeconds;
  }

  Duration _durationLeft(ConversationModel model) {
    var createdAt = (model.createdAt ?? Timestamp.now()).toDate();
    return createdAt.add(CONVERSATION_EXPIRATION).difference(DateTime.now());
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

    if (initialTimeFractionLeft <= 0 && widget.canExpire) {
      cancelTimer();
      widget.expired?.call();
      return Container();
    }

    List<dynamic> participants = ([]..addAll(conversationModel.participantIDs))..removeWhere((id) => id == currentUser.userID);

    if (participants.length == 0) {
      // TODO: add trailing action to report error to developers
      return ListTile(
        leading: CircleAvatar(child: Icon(Icons.error, color: Colors.redAccent)),
        title: Text("Oh snap!"),
        subtitle: Text("An error occurred showing this conversation :-("),
      );
    }

    if (participants.isNotEmpty && conversationState.hasUserID(participants[0])) {
      return _listItem(conversationState.getUser(participants[0]));
    }

    return FutureBuilder<AppUser>(
      future: FireStoreUtils.getUserByID(participants[0]).then((user) {
        Provider.of<ConversationData>(context, listen: false).addConversationUser(user);
        return user;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.black12,
            highlightColor: Colors.white,
            child: ListTile(
              leading: CircleAvatar(),
              title: SizedBox(width: double.maxFinite, height: 16),
              subtitle: SizedBox(width: double.maxFinite, height: 11),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data != null || snapshot.hasError) {
          return Container();
        }
        return _listItem(snapshot.data);
      },
    );

  }

  Widget _listItem(AppUser user) {
    var _widget = () {
      return InkWell(
        onTap: () {
          push(context, ChatScreen(identifiableUser: user));
        },
        child: ListTile(
          isThreeLine: true,
          leading: Avatar(user),
          title: Text(
            '${user.userName}',
            style: TextStyle(
              fontSize: 17,
              color: isDarkMode(context) ? Colors.white : Colors.black,
              fontFamily: Platform.isIOS ? 'sanFran' : 'Roboto',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lastMessage(conversationModel),
              // Text('• ${formatTimestamp(conversationModel.lastMessageDate.seconds)}',
              //   textAlign: TextAlign.right,
              //   style: TextStyle(
              //     fontSize: 11
              //   ),
              // )
            ],
          ),
          trailing: !widget.canExpire ? null : Container(
            width: 20,
            height: double.maxFinite,
            child: Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: ConversationTimer(createdAt: conversationModel.createdAt),
              ),
            ),
          ),
        ),
      );
    };

    if (!widget.canExpire) {
      return _widget();
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
        return _widget();
      }
    );
  }

  Widget _lastMessage(ConversationModel conversationModel) {
    Content messageData = conversationModel.lastMessage;
    return FutureBuilder<String>(
      future: Gecies.decrypt(Provider.of<KeyPair>(context, listen: false).privateKeyBase64, messageData.content[currentUser.userID]),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(
            '${snapshot.data}',
            overflow: TextOverflow.fade,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFACACAC),
            ),
          );
        } else if (snapshot.hasError) {
          return Icon(Icons.error, color: Colors.red,);
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
