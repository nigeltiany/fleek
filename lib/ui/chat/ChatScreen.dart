import 'dart:async';
import 'dart:io';

import 'package:audio_recorder/audio_recorder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/constants.dart';
import 'package:dating/store/ChatData.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/chat/AudioBubble.dart';
import 'package:dating/ui/chat/FileBubble.dart';
import 'package:dating/ui/chat/TextBubble.dart';
import 'package:dating/ui/chat/helpers.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { HIDDEN, VISIBLE, Recording }

class ChatScreen extends StatefulWidget {

  final AppUser chatWithUser;

  const ChatScreen({
    Key key,
    @required this.chatWithUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(chatWithUser);

}

class _ChatScreenState extends State<ChatScreen> {

  AppUser currentUser;
  Encrypter currentUsersEncrypter;
  final AppUser chatWithUser;
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _messageController = new TextEditingController();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  RecordingState currentRecordingState = RecordingState.HIDDEN;
  Timer audioMessageTimer;
  String audioMessageTime = 'Start Recording';
  bool _fetchingMessages = false;
  bool _hasMoreMessages = true;
  ScrollController _chatScrollController = ScrollController();

  String tempPathForAudioMessages;

  Recording _recording;

  _ChatScreenState(this.chatWithUser);

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    context.read<ChatData>().chattingWith(chatWithUser);
    currentUsersEncrypter = context.read<EncrypterState>().encrypter;

    context.read<ChatData>().fetchStateStream.listen((fetching) {
      _fetchingMessages = fetching;
    });
    context.read<ChatData>().chatHasMoreStateStream.listen((hasMore) {
      _hasMoreMessages = hasMore;
    });
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.extentBefore + 80 >= _chatScrollController.position.maxScrollExtent && !_fetchingMessages && _hasMoreMessages) {
        context.read<ChatData>().scrollFetch(chatWithUser);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _groupNameController.dispose();
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
        Avatar(chatWithUser),
        SizedBox(width: 12),
        Flexible(
          child: Text(chatWithUser.userName,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: _actions,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        backgroundColor: Color(COLOR_PRIMARY),
        title: _title
      ),
      body: Builder(builder: (BuildContext innerContext) {
        return Column(
          children: <Widget>[
            _messagesArea(context),
            _inputArea(context),
            _buildAudioMessageRecorder(innerContext)
          ],
        );
      }),
    );
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
            onPressed: _onCameraClick,
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
          await _sendMessage(_messageController.text, null, '');
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

  Widget _buildAudioMessageRecorder(BuildContext innerContext) {
    return Visibility(
      visible: currentRecordingState != RecordingState.HIDDEN,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child: Center(child: Text(audioMessageTime))),
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

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Send Media",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Choose image from gallery"),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image = await _imagePicker.getImage(source: ImageSource.gallery);
            if (image != null) {
              var encryptionResult = await encryptFileAtPath(image.path);
              String url = await _fireStoreUtils.uploadChatImageToFireStorage(encryptionResult.file, context);
              _sendMessage(encryptionResult.fileSecret.toString(), Url(url: url, mime: lookupMimeType(image.path)), '');
            }
          },
        ),
        // CupertinoActionSheetAction(
        //   child: Text("Choose video from gallery"),
        //   isDefaultAction: false,
        //   onPressed: () async {
        //     Navigator.pop(context);
        //     PickedFile galleryVideo = await _imagePicker.getVideo(source: ImageSource.gallery);
        //     if (galleryVideo != null) {
        //       var encryptionResult = await _encryptFileAtPath(galleryVideo.path);
        //       ChatVideoContainer videoContainer = await _fireStoreUtils.uploadChatVideoToFireStorage(encryptionResult.file, context);
        //       await _sendMessage(encryptionResult.fileSecret.toString(), videoContainer.videoUrl, videoContainer.thumbnailUrl);
        //     }
        //   },
        // ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image = await _imagePicker.getImage(source: ImageSource.camera);
            if (image != null) {
              var encryptionResult = await encryptFileAtPath(image.path);
              String url = await _fireStoreUtils.uploadChatImageToFireStorage(encryptionResult.file, context);
              await _sendMessage(encryptionResult.fileSecret.toString(), Url(url: url, mime: lookupMimeType(image.path)), '');
            }
          },
        ),
        // CupertinoActionSheetAction(
        //   child: Text("Record video"),
        //   isDestructiveAction: false,
        //   onPressed: () async {
        //     Navigator.pop(context);
        //     PickedFile recordedVideo = await _imagePicker.getVideo(source: ImageSource.camera);
        //     if (recordedVideo != null) {
        //       var encryptionResult = await _encryptFileAtPath(recordedVideo.path);
        //       ChatVideoContainer videoContainer = await _fireStoreUtils.uploadChatVideoToFireStorage(encryptionResult.file, context);
        //       await _sendMessage(encryptionResult.fileSecret.toString(), videoContainer.videoUrl, videoContainer.thumbnailUrl);
        //     }
        //   },
        // )
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
    bool isVideo = false;

    if (messageData.url != null && messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      } else if (messageData.url.mime.contains('video')) {
        mediaUrl = messageData.videoThumbnail;
        isVideo = true;
      } else if (messageData.url.mime.contains('audio')) {
        mediaUrl = messageData.url.url;
      }
    }

    if (mediaUrl.contains('audio')) {
      return AudioBubble(key: Key(messageData.messageID), messageData: messageData, audioURL: mediaUrl);
    } else if (mediaUrl.isNotEmpty) {
      return FileBubble(key: Key(messageData.messageID), messageData: messageData, mediaURL: mediaUrl, isVideo: isVideo);
    } else {
      return TextBubble(key: Key(messageData.messageID), messageData: messageData);
    }

  }

  _sendMessage(String content, Url url, String videoThumbnail) async {

    if (content.isEmpty) {
      return;
    }
    
    ConversationModel conversationModel = ConversationModel(
      lastSenderID: currentUser.userID,
      id: normalizedConversationID(currentUser.userID, chatWithUser.userID),
      participantIDs: List.unmodifiable([currentUser.userID, chatWithUser.userID]),
      lastMessageDate: Timestamp.now(),
    );

    MessageData message = MessageData(
      created: Timestamp.now(),
      content: Content(content: Map<String, String>()),
      recipientID: chatWithUser.userID,
      recipientProfilePictureURL: chatWithUser.profilePictureURL,
      senderUsername: currentUser.userName,
      senderID: currentUser.userID,
      senderProfilePictureURL: currentUser.profilePictureURL,
      url: url,
      videoThumbnail: videoThumbnail,
    );

    var otherUsersEncrypter = (String message) async {
      return await Gecies.encrypt(chatWithUser.publicKey, message);
    };
    var myMessage = await currentUsersEncrypter(content);
    var otherUsersMessage = await otherUsersEncrypter(content);
    message.content.content[currentUser.userID] = myMessage;
    message.content.content[message.recipientID] = otherUsersMessage;

    String notificationText = "";
    if (url == null) {
      conversationModel.lastMessage = message.content;
      notificationText = "${message.senderUsername} sent you a message";
    } else {
      if (url.mime.contains('image')) {
        notificationText = "${message.senderUsername} sent you a photo";
      } else if (url.mime.contains('video')) {
        notificationText = "${message.senderUsername} sent you a video";
      } else if (url.mime.contains('audio')) {
        notificationText = "${message.senderUsername} sent you a recording";
      }
      var myText = await currentUsersEncrypter(notificationText);
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
    final action = CupertinoActionSheet(
      message: Text(
        "Chat Settings",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Block user"),
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'Blocking user...', false);
            bool isSuccessful = await _fireStoreUtils.blockUser(chatWithUser, 'block');

            Navigator.of(context).pop(); // Close Dialog

            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(context, 'Block',
                  '${chatWithUser.userName} has been blocked.');
            } else {
              _showAlertDialog(context, 'Block', 'Couldn''\'t block ${chatWithUser.userName}, please try again later.');
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Report user"),
          onPressed: () async {
            Navigator.pop(context);

            showProgress(context, 'Reporting user...', false);
            bool isSuccessful = await _fireStoreUtils.blockUser(chatWithUser, 'report');
            Navigator.of(context).pop(); // Close Dialog

            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(context, 'Report', '${chatWithUser.userName} has been reported and blocked.');
            } else {
              _showAlertDialog(context, 'Report', 'Couldn''\'t report ${chatWithUser.userName}, please try again later.');
            }
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

    _recording = await AudioRecorder.stop();
    audioMessageTimer.cancel();

    setState(() {
      audioMessageTime = 'Start Recording';
      currentRecordingState = RecordingState.HIDDEN;
    });

    var encryptionResult = await encryptFileAtPath(_recording.path);
    Url url = await _fireStoreUtils.uploadAudioFile(encryptionResult.file, context);

    await _sendMessage(encryptionResult.fileSecret.toString(), url, '');
    Directory(_recording.path).deleteSync(recursive: true);

  }

  _onCancelRecording() async {
    await AudioRecorder.stop();
    audioMessageTimer.cancel();
    setState(() {
      audioMessageTime = 'Start Recording';
      currentRecordingState = RecordingState.VISIBLE;
    });
  }

  _onStartRecording(BuildContext innerContext) async {
    if (await AudioRecorder.hasPermissions) {
      await AudioRecorder.start(path: tempPathForAudioMessages, audioOutputFormat: AudioOutputFormat.AAC);
      audioMessageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          audioMessageTime = updateTime(audioMessageTimer);
        });
      });
      setState(() {
        currentRecordingState = RecordingState.Recording;
      });
    } else {
      await [Permission.microphone, Permission.storage].request();
    }
  }

}
