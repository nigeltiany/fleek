import 'dart:async';
import 'dart:io';

import 'package:audio_recorder/audio_recorder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/Avatar.dart';
import 'package:dating/constants.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/services/file_encryption.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import 'package:dating/model/ChatModel.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/chat/PlayerWidget.dart';
import 'package:dating/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:dating/ui/fullScreenVideoViewer/FullScreenVideoViewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { HIDDEN, VISIBLE, Recording }

class ChatScreen extends StatefulWidget {

  final HomeConversationModel homeConversationModel;

  const ChatScreen({Key key, @required this.homeConversationModel}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState(homeConversationModel);

}

class _ChatScreenState extends State<ChatScreen> {

  AppUser currentUser;
  Encrypter currentUsersEncrypter;
  final ImagePicker _imagePicker = ImagePicker();
  final HomeConversationModel homeConversationModel;
  TextEditingController _messageController = new TextEditingController();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  RecordingState currentRecordingState = RecordingState.HIDDEN;
  Timer audioMessageTimer;
  String audioMessageTime = 'Start Recording';

  String tempPathForAudioMessages;

  Recording _recording;

  _ChatScreenState(this.homeConversationModel);

  Stream<ChatModel> chatStream;

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    currentUsersEncrypter = context.read<EncrypterState>().encrypter;
    if (homeConversationModel.isGroupChat) {
      _groupNameController.text = homeConversationModel.conversationModel.name;
    }
    setupStream();
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _groupNameController.dispose();
  }

  setupStream() {
    chatStream = _fireStoreUtils.getChatMessages(homeConversationModel).asBroadcastStream();
    chatStream.listen((chatModel) {
      if (mounted) {
        homeConversationModel.matchedUser = chatModel.matchedUser;
        homeConversationModel.recipientEncrypter = chatModel.recipientEncrypter;
        setState(() {});
      }
    });
  }

  Iterable<Widget> get _actions {
    return <Widget>[
      PopupMenuButton(
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              child: ListTile(
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  _onPrivateChatSettingsClick();
                },
                contentPadding: const EdgeInsets.all(0),
                leading: Icon(Icons.settings, color: isDarkMode(context) ? Colors.grey.shade200 : Colors.black),
                title: Text('Settings', style: TextStyle(fontSize: 18)),
              ),
            ),
          ];
        },
      ),
    ];
  }

  Widget get _title {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Avatar(homeConversationModel),
        SizedBox(width: 12),
        Text(homeConversationModel.matchedUser.userName,
          overflow: TextOverflow.clip,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
            fontWeight: FontWeight.bold,
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
        return Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
          child: Column(
            children: <Widget>[
              _messagesArea(context),
              _inputArea(context),
              _buildAudioMessageRecorder(innerContext)
            ],
          ),
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
        child: StreamBuilder<ChatModel>(
          stream: homeConversationModel.conversationModel != null ? chatStream : null,
          initialData: ChatModel(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (snapshot.hasData && snapshot.data.message.isEmpty) {
                return Center(child: Text('No messages yet'));
              } else {
                return ListView.builder(
                  reverse: true,
                  cacheExtent: ((MediaQuery.of(context).size.height * 3).toInt() | 1000).toDouble(),
                  itemCount: snapshot.data.message.length,
                  itemBuilder: (BuildContext context, int index) {
                    return buildMessage(snapshot.data.message[index], snapshot.data.matchedUser);
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _inputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
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
              padding: const EdgeInsets.only(left: 2.0, right: 2),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: ShapeDecoration(
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(360)),
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
                padding: EdgeInsets.only(bottom: 16.0),
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
                          child: Text(
                            'Record',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget buildSubTitle(AppUser friend) {
    String text = friend.active ? 'Active now' : 'Last seen on ${setLastSeen(friend.lastOnlineTimestamp?.seconds ?? 0)}';
    return Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade200));
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
              var encryptionResult = await _encryptFileAtPath(image.path);
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
              var encryptionResult = await _encryptFileAtPath(image.path);
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
      return messageView(
        messageData,
        matchedUser,
      );
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
        displayCircleImage(sender.profilePictureURL, 35, false)
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
      return _audioClipViewer(messageData, mediaUrl);
    } else if (mediaUrl.isNotEmpty) {
      return _fileViewer(messageData, mediaURL: mediaUrl, byCurrentUser: byCurrentUser, isVideo: isVideo);
    } else {
      return _textMessageViewer(messageData, byCurrentUser: byCurrentUser);
    }

  }

  Widget _audioClipViewer(MessageData messageData, String mediaURL) {

    var fileName = Uri.parse(mediaURL).queryParameters["token"];
    if (context.read<MemoryFileSystem>().file(fileName).existsSync()) {
      return _widgetBubble(
        byCurrentUser: messageData.senderID == currentUser.userID,
        child: PlayerWidget(
          bytes: context.read<MemoryFileSystem>().file(fileName).readAsBytesSync(),
          color: isDarkMode(context) ? Colors.grey[800] : Colors.grey[200],
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        Gecies.decrypt(context.read<KeyPair>().privateKeyBase64, messageData.content.content[currentUser.userID]),
        getFile(mediaURL),
      ]),
      builder: (BuildContext innerContext, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<File>(
            future: _decryptFile((snapshot.data[0] as String), (snapshot.data[1] as File), fileName),
            builder: (BuildContext deepContext, AsyncSnapshot<File> innerSnap) {
              if (innerSnap.hasData) {
                return _widgetBubble(
                  byCurrentUser: messageData.senderID == currentUser.userID,
                  child: PlayerWidget(
                    bytes: context.read<MemoryFileSystem>().file(fileName).readAsBytesSync(),
                    color: isDarkMode(context) ? Colors.grey[800] : Colors.grey[200],
                  ),
                );
              } else if (innerSnap.hasError) {
                return _textBubble("", error: true, byCurrentUser:  messageData.senderID == currentUser.userID);
              } else {
                return SpinKitCubeGrid(color: Color(COLOR_PRIMARY_DARK));
              }
            },
          );
        } else if (snapshot.hasError) {
          return _textBubble("", error: true, byCurrentUser:  messageData.senderID == currentUser.userID);
        } else {
          return _textBubble("", loading: true, byCurrentUser:  messageData.senderID == currentUser.userID);
        }
      },
    );

  }

  Widget _fileViewer(MessageData messageData, { @required String mediaURL, bool byCurrentUser = false, bool isVideo = false }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 50,
        maxWidth: 200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _decryptedImageFileContent(messageData, mediaURL),
            messageData.videoThumbnail.isNotEmpty ?
            FloatingActionButton(
              mini: true,
              heroTag: messageData.messageID,
              backgroundColor: Color(COLOR_ACCENT),
              onPressed: () {
                push(context, FullScreenVideoViewer(heroTag: messageData.messageID, videoUrl: messageData.url.url));
              },
              child: Icon(
                Icons.play_arrow,
                color:
                isDarkMode(context) ? Colors.black : Colors.white,
              ),
            )
            :
            Container(),
          ],
        ),
      ),
    );
  }

  Future<File> getFile(String url) async {
    var name = Uri.parse(url).queryParameters["token"];
    if (await context.read<MemoryFileSystem>().file(name).exists()) {
      return Future.value(context.read<MemoryFileSystem>().file(name));
    }
    var response = await http.get(url);
    var bytes = response.bodyBytes;
    return await context.read<MemoryFileSystem>().file(name).writeAsBytes(bytes); // Caller can do whatever it needs with these bytes without rereading the file
  }

  Widget _decryptedImageFileContent(MessageData messageData, String mediaURL) {

    Widget imageRenderer (Image image) {
      return GestureDetector(
        onTap: () {
          if (messageData.videoThumbnail.isEmpty) {
            push(context, FullScreenImageViewer(image: image.image, tag: mediaURL));
          }
        },
        child: Hero(
          tag: mediaURL,
          child: image,
        ),
      );
    }

    var fileName = Uri.parse(mediaURL).queryParameters["token"];
    if (context.read<MemoryFileSystem>().file(fileName).existsSync()) {
      var image = Image.memory(context.read<MemoryFileSystem>().file(fileName).readAsBytesSync());
      return imageRenderer(image);
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        Gecies.decrypt(context.read<KeyPair>().privateKeyBase64, messageData.content.content[currentUser.userID]),
        getFile(mediaURL),
      ]),
      builder: (BuildContext innerContext, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<File>(
            future: _decryptFile((snapshot.data[0] as String), (snapshot.data[1] as File), fileName),
            builder: (BuildContext deepContext, AsyncSnapshot<File> innerSnap) {
              if (innerSnap.hasData) {
                return imageRenderer(Image.memory(innerSnap.data.readAsBytesSync()));
              } else if (innerSnap.hasError) {
                return _textBubble("", error: true, byCurrentUser:  messageData.senderID == currentUser.userID);
              } else {
                return SpinKitCubeGrid(color: Color(COLOR_PRIMARY_DARK));
              }
            },
          );
        } else if (snapshot.hasError) {
          return _textBubble("", error: true, byCurrentUser:  messageData.senderID == currentUser.userID);
        } else {
          return _textBubble("", loading: true, byCurrentUser:  messageData.senderID == currentUser.userID);
        }
      },
    );
  }

  Widget _textMessageViewer(MessageData messageData, { bool byCurrentUser = false }) {
    return FutureBuilder<String>(
      future: Gecies.decrypt(context.read<KeyPair>().privateKeyBase64, messageData.content.content[currentUser.userID]),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return _textBubble(snapshot.data, byCurrentUser: byCurrentUser);
        } else if (snapshot.hasError) {
          return _textBubble(snapshot.data, error: true, byCurrentUser: byCurrentUser);
        } else {
          return _textBubble(snapshot.data, loading: true, byCurrentUser: byCurrentUser);
        }
      },
    );
  }

  Widget _textBubble(String text, { bool loading = false, bool error = false, bool byCurrentUser = false }) {

    Widget viewChild;
    if (loading) {
      viewChild = CircularProgressIndicator();
    } else if (error) {
      viewChild = Icon(Icons.error, color: Colors.red);
    } else {
      viewChild = Text(text,
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: isDarkMode(context) ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }

    Color colorElement = byCurrentUser ? Color(COLOR_ACCENT) : (isDarkMode(context) ? Colors.grey[600] : Colors.grey[300]);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Positioned(
          right: byCurrentUser ? -8 : null,
          left: byCurrentUser ? null : -8,
          bottom: 0,
          child: Image.asset(byCurrentUser ? 'assets/images/chat_arrow_right.png' : 'assets/images/chat_arrow_left.png',
            color: colorElement,
            height: 12,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: 200,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorElement,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: viewChild,
            ),
          ),
        ),
      ],
    );
  }

  Widget _widgetBubble({ @required Widget child, bool byCurrentUser = false }) {

    Color colorElement = byCurrentUser ? Color(COLOR_ACCENT) : (isDarkMode(context) ? Colors.grey[600] : Colors.grey[300]);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Positioned(
          right: byCurrentUser ? -8 : null,
          left: byCurrentUser ? null : -8,
          bottom: 0,
          child: Image.asset(byCurrentUser ? 'assets/images/chat_arrow_right.png' : 'assets/images/chat_arrow_left.png',
            color: colorElement,
            height: 12,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: 200,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorElement,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _checkChannelNullability(ConversationModel conversationModel, MessageData messageData) async {
    if (conversationModel != null) {
      return true;
    } else {
      String channelID;
      AppUser friend = homeConversationModel.matchedUser;
      AppUser user = context.read<AppUser>();
      if (friend.userID.compareTo(user.userID) < 0) {
        channelID = "${friend.userID}:${user.userID}";
      } else {
        channelID = "${user.userID}:${friend.userID}";
      }

      ConversationModel conversation = ConversationModel(
        creatorId: user.userID,
        id: channelID,
        lastMessageDate: Timestamp.now(),
        lastMessage: messageData.content
      );
      bool isSuccessful =
      await _fireStoreUtils.createConversation(conversation);
      if (isSuccessful) {
        homeConversationModel.conversationModel = conversation;
        setupStream();
        setState(() {});
      }
      return isSuccessful;
    }
  }

  Future<EncryptionResult> _encryptFileAtPath(String path) async {
    // showProgress(context, 'Securing image...', false);
    var result = await encryptFile(LocalFileSystem(), File(path));
    // Navigator.of(context).pop();
    return result;
  }

  Future<File> _decryptFile(String secret, File file, String fileName) async {
    return await decryptFile(context.read<MemoryFileSystem>(), FileSecret.fromString(secret), file, fileName);
  }

  _sendMessage(String content, Url url, String videoThumbnail) async {

    if (content.isEmpty) {
      return;
    }

    MessageData message;

    message = MessageData(
      created: Timestamp.now(),
      content: Content(content: Map<String, String>()),
      recipientID: homeConversationModel.matchedUser.userID,
      recipientProfilePictureURL:
      homeConversationModel.matchedUser.profilePictureURL,
      senderUsername: currentUser.userName,
      senderID: currentUser.userID,
      senderProfilePictureURL: currentUser.profilePictureURL,
      url: url,
      videoThumbnail: videoThumbnail,
    );

    var otherUsersEncrypter = homeConversationModel.recipientEncrypter;

    var myMessage = await currentUsersEncrypter(content);
    var otherUsersMessage = await otherUsersEncrypter(content);
    message.content.content[currentUser.userID] = myMessage;
    message.content.content[message.recipientID] = otherUsersMessage;

    if (await _checkChannelNullability(homeConversationModel.conversationModel, message)) {

      String notificationText = "";
      if (url == null) {
        homeConversationModel.conversationModel.lastMessage = message.content;
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
        homeConversationModel.conversationModel.lastMessage = Content(content: {
          "${currentUser.userID}" : myText,
          "${message.recipientID}" : otherUsersText
        });
      }

      await _fireStoreUtils.sendMessage(
        currentUser,
        homeConversationModel.matchedUser,
        message,
        homeConversationModel.conversationModel,
        notificationText: notificationText,
      );

      homeConversationModel.conversationModel.lastMessageDate = Timestamp.now();
      await _fireStoreUtils.updateChannel(homeConversationModel.conversationModel);

    } else {

      showAlertDialog(context, 'An Error Occured', 'Couldn\'t send Message, please try again later');

    }

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
            bool isSuccessful = await _fireStoreUtils.blockUser(homeConversationModel.matchedUser, 'block');

            Navigator.of(context).pop(); // Close Dialog

            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(context, 'Block',
                  '${homeConversationModel.matchedUser.userName} has been blocked.');
            } else {
              _showAlertDialog(context, 'Block', 'Couldn''\'t block ${homeConversationModel.matchedUser.userName}, please try again later.');
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Report user"),
          onPressed: () async {
            Navigator.pop(context);

            showProgress(context, 'Reporting user...', false);
            bool isSuccessful = await _fireStoreUtils.blockUser(homeConversationModel.matchedUser, 'report');
            Navigator.of(context).pop(); // Close Dialog

            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(context, 'Report', '${homeConversationModel.matchedUser.userName} has been reported and blocked.');
            } else {
              _showAlertDialog(context, 'Report', 'Couldn''\'t report ${homeConversationModel.matchedUser.userName}, please try again later.');
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

    var encryptionResult = await _encryptFileAtPath(_recording.path);
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
