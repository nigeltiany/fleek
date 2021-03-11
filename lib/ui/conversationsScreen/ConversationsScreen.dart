import 'dart:async';

import 'package:dating/components/ConversationTile.dart';
import 'package:dating/components/MatchCard.dart';
import 'package:dating/constants.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/store/MatchData.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
        var conversations = conversationData.conversations.where((c) => c.createdAt.toDate().add(CONVERSATION_EXPIRATION).difference(DateTime.now()).inSeconds > 0);
        if (conversations.isEmpty) {
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
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return ConversationTile(
              canExpire: true,
              conversationModel: conversations.elementAt(index),
              expired: () => Future.delayed(Duration(seconds: 0), () => setState(() {})),
            );
          },
        );
      },
    );
  }

}
