import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/components/AvatarWithCountDown.dart';
import 'package:dating/components/MatchCard.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (currentUser.banned) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 72, color: Colors.red),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
            child: Text("Your account is banned. Contact hello@confab.im for more information"),
          ),
        ],
      );
    }
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _matchesList,
          Expanded(
            child: ListView(
              children: [
                _conversationsList,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _matchesList {
    return Consumer<MatchData>(
      builder: (BuildContext context, MatchData md, _) {
        if (md.matches.where((m) => m.createdAt.toDate().add(MATCH_EXPIRATION).difference(DateTime.now()).inSeconds > 0).isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text('No New Matches', style: TextStyle(fontSize: 18),),
            ),
          );
        } else {
          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: md.matches.length,
              itemBuilder: (BuildContext context, int index) {
                return MatchCard(
                  fleekMatch: md.matches[index],
                  expired: () => Future.delayed(Duration(seconds: 0), () => setState(() {})),
                );
              },
            ),
          );
        }
      },
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

    if (participants.length == 0) {
      // TODO: add trailing action to report error to developers
      return ListTile(
        leading: CircleAvatar(child: Icon(Icons.error, color: Colors.redAccent)),
        title: Text("Oh snap!"),
        subtitle: Text("An error occurred showing this conversation :-("),
      );
    }

    var listItem = (AppUser user) {
      return InkWell(
        onTap: () {
          push(context, ChatScreen(identifiableUser: user,));
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

    if (participants.isNotEmpty && conversationState.hasUserID(participants[0])) {
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

}
