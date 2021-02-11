import 'dart:io';

import 'package:dating/components/Avatar.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/HomeConversationModel.dart';
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

class ConversationsScreen extends StatefulWidget {
  final AppUser user;

  const ConversationsScreen({Key key, @required this.user}) : super(key: key);

  @override
  State createState() {
    return _ConversationsState(user);
  }
}

class _ConversationsState extends State<ConversationsScreen> {
  final AppUser user;
  final fireStoreUtils = FireStoreUtils();
  Future<List<AppUser>> _matchesFuture;
  Stream<List<HomeConversationModel>> _conversationsStream;

  _ConversationsState(this.user);

  @override
  void initState() {
    super.initState();
    fireStoreUtils.getBlocks().listen((shouldRefresh) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
    _matchesFuture = fireStoreUtils.getMatchedUserObject(user.userID);
    _conversationsStream = fireStoreUtils.getConversations(user.userID);
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
      child: FutureBuilder<List<AppUser>>(
        future: _matchesFuture,
        initialData: [],
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(COLOR_ACCENT)),
                ),
              ),
            );
          } else if (!snap.hasData || snap.data.isEmpty) {
            return Center(
              child: Text(
                'No Matches found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snap.hasData ? snap.data.length : 0,
              // ignore: missing_return
              itemBuilder: (BuildContext context, int index) {
                if (snap.hasData) {
                  AppUser friend = snap.data[index];
                  return fireStoreUtils.validateIfUserBlocked(friend.userID)
                      ? Container(
                    width: 0,
                    height: 0,
                  )
                  :
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                    child: InkWell(
                      onLongPress: () => _onMatchLongPress(friend),
                      onTap: () async {
                        String channelID;
                        if (friend.userID.compareTo(user.userID) < 0) {
                          channelID = friend.userID + ':' + user.userID;
                        } else {
                          channelID = user.userID + ':' + friend.userID;
                        }
                        ConversationModel conversationModel = await fireStoreUtils.getChannelByIdOrNull(channelID);
                        push(context,
                          ChatScreen(
                            homeConversationModel: HomeConversationModel(
                              isGroupChat: false,
                              members: [friend],
                              conversationModel: conversationModel,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: <Widget>[
                          displayCircleImage(friend.profilePictureURL, 50, false),
                          Expanded(
                            child: Container(
                              width: 75,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, left: 8, right: 8),
                                child: Text(
                                  '${friend.userName}',
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
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget get _conversationsList {
    return StreamBuilder<List<HomeConversationModel>>(
      stream: _conversationsStream,
      initialData: [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(COLOR_ACCENT)),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data.isEmpty) {
          return Center(
            child: Text(
              'No Conversations found.',
              style: TextStyle(fontSize: 18),
            ),
          );
        } else {
          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final homeConversationModel = snapshot.data[index];

              if (fireStoreUtils.validateIfUserBlocked(homeConversationModel.members.first.userID)) {
                return Container();
              } else {
                return _buildConversationRow(homeConversationModel);
              }
            },
          );
        }
      },
    );
  }

  Widget _avatarWithStatus(HomeConversationModel homeConversationModel) {
    return  Avatar(homeConversationModel);
  }

  Widget _lastMessage(HomeConversationModel homeConversationModel) {
    Content messageData = homeConversationModel.conversationModel.lastMessage;
    return FutureBuilder<String>(
      future: Gecies.decrypt(context.read<KeyPair>().privateKeyBase64, messageData.content[user.userID]),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(
            '${snapshot.data} • ${formatTimestamp(homeConversationModel.conversationModel.lastMessageDate.seconds)}',
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

  Widget _buildConversationRow(HomeConversationModel homeConversationModel) {
    return InkWell(
      onTap: () {
        push(context, ChatScreen(homeConversationModel: homeConversationModel));
      },
      child: ListTile(
        leading: _avatarWithStatus(homeConversationModel),
        title: Text(
          '${homeConversationModel.members.first.userName}',
          style: TextStyle(
            fontSize: 17,
            color: isDarkMode(context) ? Colors.white : Colors.black,
            fontFamily: Platform.isIOS ? 'sanFran' : 'Roboto',
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _lastMessage(homeConversationModel),
        ),
      ),
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
