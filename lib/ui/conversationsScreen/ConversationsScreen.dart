import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ConversationsScreen extends StatefulWidget {

  const ConversationsScreen({Key key}) : super(key: key);

  @override
  State createState() {
    return _ConversationsState();
  }

}

class _ConversationsState extends State<ConversationsScreen> {

  AppUser currentUser;
  ConversationData conversationState;
  final fireStoreUtils = FireStoreUtils();

  _ConversationsState();

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    conversationState = context.read<ConversationData>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[
          _matchesList,
          _conversationsList,
        ],
      ),
    );
  }

  Widget get _matchesList {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(MATCHES).doc(currentUser.userID).collection('matches').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(COLOR_ACCENT)),
                ),
              ),
            );
          } else if (!snap.hasData || snap.data.docs.isEmpty) {
            return Center(
              child: Text('No Matches found.', style: TextStyle(fontSize: 18),),
            );
          } else {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snap.hasData ? snap.data.size : 0,
              // ignore: missing_return
              itemBuilder: (BuildContext context, int index) {
                FleekMatch match = FleekMatch.fromJson(snap.data.docs[index].data());
                return FutureBuilder<AppUser>(
                  future: FireStoreUtils.getUserByID(match.matchUserID),
                  builder: (BuildContext context, AsyncSnapshot userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        child: CircularProgressIndicator(),
                      );
                    } else if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data is AppUser) {
                      conversationState.addConversationUser(userSnapshot.data);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                        child: InkWell(
                          onLongPress: () => _onMatchLongPress(userSnapshot.data),
                          onTap: () async {
                            push(context, ChatScreen(chatWithUser: userSnapshot.data));
                          },
                          child: Column(
                            children: <Widget>[
                              displayCircleImage(userSnapshot.data.profilePictureURL, 50, false),
                              Expanded(
                                child: Container(
                                  width: 75,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                                    child: Text('${userSnapshot.data.userName}',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget get _conversationsList {
    return Consumer<ConversationData>(
      builder: (context, conversationData, _) {
        if (conversationData.conversations.isEmpty) {
          return Center(
            child: Text(
              'No Conversations found.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        return ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: conversationData.conversations.length,
          itemBuilder: (context, index) {
            return _buildConversationRow(conversationData.conversations[index]);
          },
        );
      },
    );
  }

  Widget _lastMessage(ConversationModel conversationModel) {
    Content messageData = conversationModel.lastMessage;
    return FutureBuilder<String>(
      future: Gecies.decrypt(context.read<KeyPair>().privateKeyBase64, messageData.content[currentUser.userID]),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(
            '${snapshot.data} • ${formatTimestamp(conversationModel.lastMessageDate.seconds)}',
            maxLines: 1,
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

  Widget _buildConversationRow(ConversationModel conversationModel) {

    List<dynamic> participants = ([]..addAll(conversationModel.participantIDs))..removeWhere((id) => id == currentUser.userID);

    var listItem = (AppUser user) {
      return InkWell(
        onTap: () {
          push(context, ChatScreen(chatWithUser: user,));
        },
        child: ListTile(
          leading: Avatar(user),
          title: Text(
            '${user.userName}',
            style: TextStyle(
              fontSize: 17,
              color: isDarkMode(context) ? Colors.white : Colors.black,
              fontFamily: Platform.isIOS ? 'sanFran' : 'Roboto',
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _lastMessage(conversationModel),
          ),
        ),
      );
    };

    if (conversationState.hasUserID(participants[0])) {
      return listItem(conversationState.getUser(participants[0]));
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
        return listItem(snapshot.data);
      },
    );
  }

  _onMatchLongPress(AppUser friend) {
    final action = CupertinoActionSheet(
      message: Text(
        friend.userName,
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("View Profile"),
          isDefaultAction: true,
          onPressed: () async {
            Navigator.pop(context);
            push(context, UserDetailsScreen(user: friend, isMatch: true,));
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          "Cancel",
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

}
