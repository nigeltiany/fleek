import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/components/Snackbars.dart';
import 'package:dating/constants.dart';
import 'package:dating/services/file_encryption.dart';
import 'package:dating/store/ChatData.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/ui/chat/AudioBubble.dart';
import 'package:dating/ui/chat/FileBubble.dart';
import 'package:dating/ui/chat/TextBubble.dart';
import 'package:dating/ui/chat/helpers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:gecies/gecies.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { HIDDEN, VISIBLE, Recording }

class ChatScreen extends StatefulWidget {

  final IdentifiableUser identifiableUser;

  const ChatScreen({
    Key key,
    @required this.identifiableUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(identifiableUser);

}

class _ChatScreenState extends State<ChatScreen> {

  AppUser currentUser;
  Encrypter currentUsersEncrypter;
  final IdentifiableUser identifiableUser;
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _messageController = new TextEditingController();
  RecordingState currentRecordingState = RecordingState.HIDDEN;
  Timer audioMessageTimer;
  String audioMessageTime = 'Start Recording';
  bool _fetchingMessages = false;
  bool _hasMoreMessages = true;
  ScrollController _chatScrollController = ScrollController();

  String tempPathForAudioMessages;
  AppUser chatWithUser;
  FlutterSoundRecorder _soundRecorder = FlutterSoundRecorder();

  OverlayEntry customSnackBar;
  OverlayWithUpdater customProgressBar;

  ChatData chatData;

  _ChatScreenState(this.identifiableUser);

  @override
  void initState() {

    super.initState();
    currentUser = context.read<AppUser>();
    currentUsersEncrypter = context.read<EncrypterState>().encrypter;

    chatData = context.read<ChatData>();
    chatData.fetchStateStream.listen((fetching) {
      _fetchingMessages = fetching;
    });
    chatData.chatHasMoreStateStream.listen((hasMore) {
      _hasMoreMessages = hasMore;
    });
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.extentBefore + 80 >= _chatScrollController.position.maxScrollExtent && !_fetchingMessages && _hasMoreMessages) {
        if (chatWithUser != null) {
          chatData.scrollFetch(chatWithUser);
        }
      }
    });
    FireStoreUtils.updateLastViewed(normalizedConversationID(currentUser.userID, identifiableUser.userID));
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    chatData.activeChatDone();
  }

  Iterable<Widget> get _actions {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.more_vert),
        onPressed: () {
          _onPrivateChatSettingsClick();
        },
      ),
    ];
  }

  Widget get _title {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Avatar(chatWithUser ?? identifiableUser),
        SizedBox(width: 12),
        Flexible(
          child: Text(chatWithUser?.userName ?? "",
            overflow: TextOverflow.fade,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


  Widget _body(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(
        actions: _actions,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        backgroundColor: Color(COLOR_PRIMARY),
        title: _title
      ),
      body: Column(
        children: <Widget>[
          _messagesArea(context),
          _inputArea(context),
          _buildAudioMessageRecorder(context)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    chatWithUser = Provider.of<ConversationData>(context, listen: false).getUser(identifiableUser.userID);

    if (chatWithUser == null) {
      return FutureBuilder<AppUser>(
        future: FireStoreUtils.getUserByID(identifiableUser.userID).then((user) {
          Provider.of<ConversationData>(context, listen: false).addConversationUser(user);
          Provider.of<ChatData>(context, listen: false).chattingWith(user);
          chatWithUser = user;
          return user;
        }),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return _body(context);
          }
          return Container(
            color: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
            child: Center(
              child: snapshot.hasError ? Icon(Icons.error, color: Colors.redAccent) : CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    Provider.of<ChatData>(context, listen: false).chattingWith(chatWithUser);

    return _body(context);

  }

  Widget _messagesArea(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            currentRecordingState = RecordingState.HIDDEN;
          });
        },
        child: Consumer<ChatData>(
          builder: (BuildContext context, ChatData chatData, _) {
            if (chatData.messages.isEmpty) {
              return Center(child: Text('No messages yet'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 50, bottom: 50),
              reverse: true,
              controller: _chatScrollController,
              cacheExtent: ((MediaQuery.of(context).size.height * 3).toInt() | 1000).toDouble(),
              itemCount: chatData.messages.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: buildMessage(chatData.messages[index], chatWithUser),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _inputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              _onCameraClick(context);
            },
            icon: Icon(
              Icons.camera_alt,
              color: Color(COLOR_PRIMARY),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: ShapeDecoration(
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(style: BorderStyle.none),
                  ),
                  color: isDarkMode(context) ? Colors.grey[700] : Colors.grey.shade200,
                ),
                child: TextField(
                  controller: _messageController,
                  textAlignVertical: TextAlignVertical.center,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  decoration: _inputAreaDecoration,
                  onChanged: (s) {
                    setState(() {});
                  },
                  onTap: () {
                    setState(() {
                      currentRecordingState = RecordingState.HIDDEN;
                    });
                  },
                ),
              ),
            ),
          ),
          _chatAction(),
        ],
      ),
    );
  }

  Widget _chatAction() {
    if (_messageController.text.isEmpty) {
      return IconButton(
        icon: Icon(Icons.mic,
          color: currentRecordingState == RecordingState.HIDDEN ? Color(COLOR_PRIMARY) : Colors.red,
        ),
        onPressed: _onMicClicked,
      );
    }
    return IconButton(
      icon: Icon(Icons.send,
        color: Color(COLOR_PRIMARY),
      ),
      onPressed: () async {
        if (_messageController.text.isNotEmpty) {
          await _sendMessage(_messageController.text, null);
          _messageController.clear();
          setState(() {});
        }
      },
    );
  }

  InputDecoration get _inputAreaDecoration {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      hintText: 'Start typing...',
      hintStyle: TextStyle(color: Colors.grey[400]),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(360)),
        borderSide: BorderSide(style: BorderStyle.none),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(360)),
        borderSide: BorderSide(style: BorderStyle.none),
      ),
    );
  }

  Color get _recordingMessageColor {
    return isDarkMode(context) ? Colors.white : Colors.black;
  }

  Widget _buildAudioMessageRecorder(BuildContext innerContext) {
    return Visibility(
      visible: currentRecordingState != RecordingState.HIDDEN,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Text(audioMessageTime,
                  style: TextStyle(
                    fontSize: audioMessageTime == 'Start Recording' ? 16 : 32,
                    color: (audioMessageTimer != null ? (Duration(seconds: audioMessageTimer.tick).inMinutes > 2 ? Colors.redAccent : _recordingMessageColor) : _recordingMessageColor),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.0, left: 24, right: 24),
                child: Stack(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Visibility(
                            visible: currentRecordingState == RecordingState.Recording,
                            child: RaisedButton(
                              color: Color(COLOR_PRIMARY),
                              child: Text('Send',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              textColor: Colors.white,
                              onPressed: () => _onSendRecord(),
                              padding: EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: BorderSide(style: BorderStyle.none),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Visibility(
                            visible: currentRecordingState == RecordingState.Recording,
                            child: RaisedButton(
                              color: Colors.grey[700],
                              child: Text('Cancel',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              textColor: Colors.white,
                              onPressed: () => _onCancelRecording(),
                              padding: EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: BorderSide(style: BorderStyle.none),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Visibility(
                        visible:
                        currentRecordingState == RecordingState.VISIBLE,
                        child: RaisedButton(
                          color: Colors.red,
                          child: Text('Record',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          textColor: Colors.white,
                          onPressed: () => _onStartRecording(innerContext),
                          padding: EdgeInsets.only(top: 12, bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            side: BorderSide(style: BorderStyle.none),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        height: MediaQuery.of(context).size.height * .3,
      ),
    );
  }

  _onCameraClick(BuildContext context) {

    final action = Container(
      color: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("Send Media",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Color(COLOR_PRIMARY_DARK),
              ),
            ),
          ),
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text("Take a picture"),
                leading: Icon(Icons.camera_alt_rounded),
                onTap: () async {
                  Navigator.pop(context);
                  PickedFile image = await _imagePicker.getImage(source: ImageSource.camera);
                  _sendImage(image);
                },
              ),
              ListTile(
                title: Text("Choose image from gallery"),
                leading: Icon(Icons.add_photo_alternate),
                onTap: () async {
                  Navigator.pop(context);
                  PickedFile image = await _imagePicker.getImage(source: ImageSource.gallery);
                  _sendImage(image);
                },
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );

    showModalBottomSheet(context: context, builder: (context) => action);

  }

  Widget buildMessage(MessageData messageData, AppUser matchedUser) {
    if (messageData.senderID == currentUser.userID) {
      return messageView(messageData, currentUser, byCurrentUser: true);
    } else {
      return messageView(messageData, matchedUser);
    }
  }

  Widget messageView(MessageData messageData, AppUser sender, { bool byCurrentUser = false }) {
    if (messageData.content.content.containsKey(sender.userID)) {
      
      List<Widget> messageItems = [
        Padding(
          padding: EdgeInsets.only(
            right: (byCurrentUser ? 12.0 : 0.0),
            left: (byCurrentUser ? 0.0 : 12.0),
          ),
          child: _messageContentWidget(messageData, byCurrentUser: byCurrentUser),
        ),
        // displayCircleImage(sender.profilePictureURL, 35, false)
      ];
      
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          crossAxisAlignment: byCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisAlignment: byCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: byCurrentUser ? messageItems : messageItems.reversed.toList(growable: false),
        ),
      );
    } else {
     return Container();
    }
  }

  Widget _messageContentWidget(MessageData messageData, { bool byCurrentUser = false }) {

    String mediaUrl = '';
    // bool isVideo = false;

    if (messageData.url != null && messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      // } else if (messageData.url.mime.contains('video')) {
      //   mediaUrl = messageData.videoThumbnail;
      //   isVideo = true;
      } else if (messageData.url.mime.contains('audio')) {
        mediaUrl = messageData.url.url;
      }
    }

    if (mediaUrl.contains('audio')) {
      return AudioBubble(key: Key(messageData.messageID), messageData: messageData, audioURL: mediaUrl);
    } else if (mediaUrl.isNotEmpty) {
      return FileBubble(key: Key(messageData.messageID), messageData: messageData, mediaURL: mediaUrl, isVideo: false);
    } else {
      return TextBubble(key: Key(messageData.messageID), messageData: messageData);
    }

  }

  _sendImage(PickedFile image) async {
    if (image != null) {
      _clearExistingSnackBars();
      customSnackBar = showEncryptingSnackBar(context, FileType.IMAGE);
      await encryptFileAtPath(image.path).catchError((e) {
        customSnackBar.remove();
        _showAlertDialog(context, "Encryption Error", "Unable to encrypt image");
      }).then((EncryptionResult encryptionResult) async {
        customSnackBar.remove();
        customProgressBar = showUploadingSnackBar(context);
        await FireStoreUtils.uploadChatImageToFireStorage(
          context,
          encryptionResult.file,
          normalizedConversationID(currentUser.userID, chatWithUser.userID),
          progressCallback: customProgressBar.updatedCallback
        ).catchError((e) {
          customProgressBar.overlayEntry.remove();
          _showAlertDialog(context, "Upload Error", "Unable to upload image");
        }).then((String url) async {
          customProgressBar.overlayEntry.remove();
          await _sendMessage(encryptionResult.fileSecret.toString(), Url(url: url, mime: lookupMimeType(image.path)));
        });
      });
    }
  }

  _sendMessage(String content, Url url) async {

    if (content.trim().isEmpty) {
      return;
    }

    var now = Timestamp.now();
    
    ConversationModel conversationModel = ConversationModel(
      creatorID: currentUser.userID,
      id: normalizedConversationID(currentUser.userID, chatWithUser.userID),
      participantIDs: List.unmodifiable([currentUser.userID, chatWithUser.userID]),
      lastMessageDate: now,
      lastViewedDate: {
        "${currentUser.userID}": now,
      }
    );

    MessageData message = MessageData(
      created: now,
      content: Content(content: Map<String, String>()),
      recipientID: chatWithUser.userID,
      recipientProfilePictureURL: chatWithUser.profilePictureURL,
      senderUsername: currentUser.userName,
      senderID: currentUser.userID,
      senderProfilePictureURL: currentUser.profilePictureURL,
      url: url,
    );

    var otherUsersEncrypter = (String message) async {
      return await Gecies.encrypt(chatWithUser.publicKey, message);
    };
    var myMessage = await currentUsersEncrypter(content);
    var otherUsersMessage = await otherUsersEncrypter(content);
    message.content.content[currentUser.userID] = myMessage;
    message.content.content[message.recipientID] = otherUsersMessage;

    String notificationText = "${message.senderUsername} sent you a message";
    if (url == null) {
      conversationModel.lastMessage = message.content;
    } else {
      if (url.mime.contains('image')) {
        notificationText = "${message.senderUsername} sent you a photo";
      } else if (url.mime.contains('video')) {
        notificationText = "${message.senderUsername} sent you a video";
      } else if (url.mime.contains('audio')) {
        notificationText = "${message.senderUsername} sent you a recording";
      }
      var myText = await currentUsersEncrypter(notificationText.replaceFirst("${message.senderUsername}", "You").replaceFirst("you a", "a"));
      var otherUsersText = await otherUsersEncrypter(notificationText);
      conversationModel.lastMessage = Content(content: {
        "${currentUser.userID}" : myText,
        "${message.recipientID}" : otherUsersText
      });
    }

    // update conversation model first
    await FireStoreUtils.updateChannel(conversationModel);
    await FireStoreUtils.sendMessage(currentUser, chatWithUser, message, notificationText: notificationText);

  }

  _onPrivateChatSettingsClick() {

    showDialog(
      context: context,
      builder: (BuildContext innerContext) {
        return SimpleDialog(
          titlePadding: EdgeInsets.symmetric(horizontal: 8),
          title: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            toolbarHeight: 64,
            leading: Center(child: Avatar(chatWithUser)),
            title: Text(chatWithUser.userName ?? "",
              style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ),
          ),
          children: [
            ListTile(
              title: Text("Unmatch"),
              onTap: () async {
                Navigator.pop(context); // Close Dialog

                await FireStoreUtils.removeMatch(identifiableUser).catchError((e) => print(e));
                var cid = normalizedConversationID(currentUser.userID, chatWithUser.userID);
                Provider.of<ConversationData>(context, listen: false).removeConversation(cid);
                Provider.of<MatchData>(context, listen: false).removeCachedMatch(chatWithUser);

                Navigator.of(context).pop();
              },
            ),
            Divider(),
            SizedBox(height: 8),
            ListTile(
              title: Text("Block user",
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                showProgress(context, 'Blocking user...', false);

                bool isSuccessful = await FireStoreUtils.blockUser(identifiableUser).catchError((e) => print(e));
                var cid = normalizedConversationID(currentUser.userID, chatWithUser.userID);
                Provider.of<ConversationData>(context, listen: false).removeConversation(cid);
                Provider.of<MatchData>(context, listen: false).removeCachedMatch(chatWithUser);
                Navigator.of(context).pop(); // Close Dialog

                if (isSuccessful) {
                  Navigator.pop(context);
                  _showAlertDialog(context, 'Block successful', '${chatWithUser.userName} has been blocked.');
                } else {
                  _showAlertDialog(context, 'Block', 'Couldn''\'t block ${chatWithUser.userName}, please try again later.');
                }
              },
            ),
          ],
        );
      }
    );

  }

  _showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _onMicClicked() async {
    if (currentRecordingState == RecordingState.HIDDEN) {
      FocusScope.of(context).unfocus();
      Directory tempDir = await getTemporaryDirectory();
      var uniqueID = Uuid().v4();
      tempPathForAudioMessages = '${tempDir.path}/$uniqueID';
      currentRecordingState = RecordingState.VISIBLE;
    } else {
      currentRecordingState = RecordingState.HIDDEN;
    }
    setState(() {});
  }

  _onSendRecord() async {

    var _path = await _soundRecorder.stopRecorder();
    audioMessageTimer.cancel();

    setState(() {
      audioMessageTime = 'Start Recording';
      currentRecordingState = RecordingState.HIDDEN;
    });

    _clearExistingSnackBars();
    customSnackBar = showEncryptingSnackBar(context, FileType.AUDIO);
    await encryptFileAtPath(_path).catchError((e) {
      customSnackBar.remove();
      _showAlertDialog(context, "Encryption Error", "Unable to encrypt recording");
    }).then((EncryptionResult encryptionResult) async {
      customSnackBar.remove();
      customProgressBar = showUploadingSnackBar(context);
      await FireStoreUtils.uploadAudioFile(
        encryptionResult.file,
        context,
        progressCallback: customProgressBar.updatedCallback
      ).catchError((e) {
        customProgressBar.overlayEntry.remove();
        _showAlertDialog(context, "Encryption Error", "Unable to upload audio message");
      }).then((Url url) async {
        await _sendMessage(encryptionResult.fileSecret.toString(), url);
      });
    });

    await _soundRecorder.closeAudioSession();
    Directory(_path).deleteSync(recursive: true);

  }

  _onCancelRecording() async {
    audioMessageTimer.cancel();
    var _path = await _soundRecorder.stopRecorder();
    if (_path != null) {
      await Directory(_path).delete(recursive: true);
    }
    await _soundRecorder.closeAudioSession();
    setState(() {
      audioMessageTime = 'Start Recording';
      currentRecordingState = RecordingState.VISIBLE;
    });
  }

  _onStartRecording(BuildContext innerContext) async {

    var perm = await Permission.microphone.request();
    if (perm != PermissionStatus.granted) {
      _onMicClicked();
      return;
    }

    await _soundRecorder.openAudioSession().then((value) {
      _soundRecorder.startRecorder(
        codec: Codec.aacADTS,
        toFile: tempPathForAudioMessages,
      );
      audioMessageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (Duration(seconds: audioMessageTimer.tick).inMinutes >= 5) {
          _onSendRecord();
        }
        setState(() {
          audioMessageTime = updateTime(audioMessageTimer);
        });
      });
      setState(() {
        currentRecordingState = RecordingState.Recording;
      });
    }).catchError((_) {
      _showAlertDialog(context, "Recording Error", "Unable to create and send a recording");
    });
  }

  _clearExistingSnackBars () {
    if (customSnackBar != null) {
      if (customSnackBar.mounted) {
        customSnackBar.remove();
      }
    }
    if (customProgressBar != null) {
      if (customProgressBar.overlayEntry.mounted) {
        customProgressBar.overlayEntry.remove();
      }
    }
  }

}