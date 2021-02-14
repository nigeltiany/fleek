import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/model/BlockUserModel.dart';
import 'package:dating/model/ChannelParticipation.dart';
import 'package:dating/model/ChatModel.dart';
import 'package:dating/model/ChatVideoContainer.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/Gender.dart';
import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/model/SwipeCounterModel.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/ui/matchScreen/MatchScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gecies/gecies.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:path/path.dart' as Path;
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../constants.dart';

final geo = Geoflutterfire();


class FireStoreUtils {

  static FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  Reference storage = FirebaseStorage.instance.ref();
  List<Swipe> matchedUsersList = [];
  StreamController<List<HomeConversationModel>> conversationsStream;
  List<HomeConversationModel> homeConversations = [];
  List<BlockUserModel> blockedList = [];
  List<AppUser> matches = [];
  StreamController fleekCardsStreamController;

  static Future<UserPrivateDetails> getCurrentUserPrivateDetails() async {
    DocumentSnapshot userDocument = await firestore.collection(USERS_PRIVATE).doc(FirebaseAuth.instance.currentUser.uid).get();
    if (userDocument != null && userDocument.exists) {
      return UserPrivateDetails.fromJson(userDocument.data());
    } else {
      return null;
    }
  }

  static Future<AppUser> getCurrentUser() async {
    DocumentSnapshot userDocument = await firestore.collection(USERS).doc(FirebaseAuth.instance.currentUser.uid).get();
    if (userDocument != null && userDocument.exists) {
      return AppUser.fromJson(userDocument.data());
    } else {
      return null;
    }
  }

  static Future<AppUser> updateCurrentUser(AppUser user) async {
    return await firestore
        .collection(USERS)
        .doc(FirebaseAuth.instance.currentUser.uid)
        .set(user.toJson(), SetOptions(merge: true))
        .then((document) {
      return user;
    });
  }

  static Future<UserPrivateDetails> updateUserPrivateDetails(UserPrivateDetails user) async {
    return await firestore
        .collection(USERS_PRIVATE)
        .doc(FirebaseAuth.instance.currentUser.uid)
        .set(user.toJson(), SetOptions(merge: true))
        .then((document) {
      return user;
    });
  }

  Future<String> uploadUserImageToFireStorage(AppUser user, File image, String userID) async {
    if (user.profilePictureURL != null && user.profilePictureURL.isNotEmpty) {
      await FirebaseStorage.instance.refFromURL(user.profilePictureURL).delete();
    }
    Reference upload = storage.child("profile_picture/$userID/${Uuid().v4()}.png");
    UploadTask uploadTask = upload.putFile(image);
    await uploadTask;
    return await uploadTask.snapshot.ref.getDownloadURL();
  }

  Future<String> uploadChatImageToFireStorage(image, BuildContext context) async {

    showProgress(context, 'Uploading image...', false);

    var uniqueID = Uuid().v4();
    Reference upload = storage.child("images/$uniqueID.png");
    UploadTask uploadTask = upload.putFile(image);

    uploadTask.snapshotEvents.listen((event) {
      updateProgress(
        'Uploading image ${(event.bytesTransferred.toDouble() / 1000)
          .toStringAsFixed(2)} /'
          '${(event.totalBytes.toDouble() / 1000)
          .toStringAsFixed(2)} '
          'KB'
      );
    });

    await uploadTask;
    Navigator.of(context).pop();

    return uploadTask.snapshot.ref.getDownloadURL();

  }

  Future<ChatVideoContainer> uploadChatVideoToFireStorage(video, BuildContext context) async {
    // showProgress(context, 'Uploading video...', false);
    // var uniqueID = Uuid().v4();
    // Reference upload = storage.child("videos/$uniqueID.mp4");
    // SettableMetadata metadata = new SettableMetadata(contentType: 'video');
    // UploadTask uploadTask = upload.putFile(video, metadata);
    // uploadTask.events.listen((event) {
    //   updateProgress(
    //       'Uploading video ${(event.snapshot.bytesTransferred.toDouble() / 1000)
    //           .toStringAsFixed(2)} /'
    //           '${(event.snapshot.totalByteCount.toDouble() / 1000)
    //           .toStringAsFixed(2)} '
    //           'KB');
    // });
    // var storageRef = (await uploadTask.onComplete).ref;
    // var downloadUrl = await storageRef.getDownloadURL();
    // var metaData = await storageRef.getMetadata();
    // final uint8list = await VideoThumbnail.thumbnailFile(
    //     video: downloadUrl,
    //     thumbnailPath: (await getTemporaryDirectory()).path,
    //     imageFormat: ImageFormat.PNG);
    // final file = File(uint8list);
    // String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
    // Navigator.of(context).pop(); // Close Dialog
    // return ChatVideoContainer(
    //     videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType),
    //     thumbnailUrl: thumbnailDownloadUrl);
  }

  Future<String> uploadVideoThumbnailToFireStorage(file) async {
    // var uniqueID = Uuid().v4();
    // Reference upload = storage.child("thumbnails/$uniqueID.png");
    // UploadTask uploadTask = upload.putFile(file);
    // var downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    // return downloadUrl.toString();
  }

  Future<List<Swipe>> getMatches(String userID) async {
    List matchList = List<Swipe>();
    await firestore
        .collection(SWIPES)
        .where('swiperUserID', isEqualTo: userID)
        .where('hasBeenSeen', isEqualTo: true)
        .get()
        .then((querysnapShot) {
      querysnapShot.docs.forEach((doc) {
        Swipe match = Swipe.fromJson(doc.data());
        if (match.id.isEmpty) {
          match.id = doc.id;
        }
        matchList.add(match);
      });
    });
    return matchList.toSet().toList();
  }

  Future<bool> removeMatch(String id) async {
    bool isSuccessful;
    await firestore.collection(SWIPES).doc(id).delete().then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      print('${e.toString()}');
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<List<AppUser>> getMatchedUserObject(String userID) async {
    List<String> friendIDs = [];
    matchedUsersList.clear();
    matchedUsersList = await getMatches(userID);
    matchedUsersList.forEach((matchedUser) {
      friendIDs.add(matchedUser.forUserID);
    });
    matches.clear();
    for (String id in friendIDs) {
      await firestore.collection(USERS).doc(id).get().then((user) {
        matches.add(AppUser.fromJson(user.data()));
      });
    }
    return matches;
  }

  Stream<List<HomeConversationModel>> getConversations(String userID) async* {

    conversationsStream = StreamController<List<HomeConversationModel>>();
    HomeConversationModel newHomeConversation;

    firestore
        .collection(CHANNEL_PARTICIPATION)
        .where('user', isEqualTo: userID)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        conversationsStream.sink.add(homeConversations);
      } else {
        homeConversations.clear();
        Future.forEach(querySnapshot.docs, (DocumentSnapshot document) {
          if (document != null && document.exists) {
            ChannelParticipation participation =
            ChannelParticipation.fromJson(document.data());
            firestore
                .collection(CHANNELS)
                .doc(participation.channel)
                .snapshots()
                .listen((channel) async {
              if (channel != null && channel.exists) {

                bool isGroupChat = !channel.id.contains(userID);

                getUserByID(channel.id.replaceAll(userID, '').replaceAll(':', '')).listen((user) {
                  newHomeConversation = HomeConversationModel(
                      conversationModel: ConversationModel.fromJson(channel.data()),
                      isGroupChat: isGroupChat,
                      matchedUser: user,
                  );

                  if (newHomeConversation.conversationModel.id.isEmpty) {
                    newHomeConversation.conversationModel.id = channel.id;
                  }

                  homeConversations.removeWhere((conversationModelToDelete) {
                    return newHomeConversation.conversationModel.id == conversationModelToDelete.conversationModel.id;
                  });

                  homeConversations.add(newHomeConversation);
                  homeConversations.sort((a, b) => a
                    .conversationModel.lastMessageDate
                    .compareTo(b.conversationModel.lastMessageDate));
                  conversationsStream.sink.add(homeConversations.reversed.toList());

                });

              }
            });
          }
        });
      }
    });
    yield* conversationsStream.stream;
  }

  Stream<AppUser> getUserByID(String id) async* {
    StreamController<AppUser> userStreamController = StreamController();
    firestore.collection(USERS).doc(id).snapshots().listen((user) {
      if (user.data != null) {
        userStreamController.sink.add(AppUser.fromJson(user.data()));
      }
    });
    yield* userStreamController.stream;
  }

  Future<ConversationModel> getChannelByIdOrNull(String channelID) async {
    ConversationModel conversationModel;
    await firestore.collection(CHANNELS).doc(channelID).get().then((channel) {
        if (channel != null && channel.exists) {
          conversationModel = ConversationModel.fromJson(channel.data());
        }
      },
    ).catchError((e) {
      print((e as PlatformException).message);
    });
    return conversationModel;
  }

  Stream<ChatModel> getChatMessages(HomeConversationModel homeConversationModel) async* {

    // ignore: close_sinks
    StreamController<ChatModel> chatModelStreamController = StreamController();
    ChatModel chatModel = ChatModel();
    List<MessageData> listOfMessages = [];

    AppUser matchedUser = homeConversationModel.matchedUser;
    getUserByID(matchedUser.userID).listen((user) {
      chatModel.messages = listOfMessages;
      chatModel.matchedUser = user;
      chatModel.recipientEncrypter = (String message) async {
        return await Gecies.encrypt(user.publicKey, message);
      };
      chatModelStreamController.sink.add(chatModel);
    });

    if (homeConversationModel.conversationModel == null) {
      print("home conversation model cannot be null");
      return;
    }

    var snapshot = await firestore
      .collection(CHANNELS)
      .doc(homeConversationModel.conversationModel.id)
      .collection(THREAD)
      .limit(50)
      .orderBy('createdAt', descending: true).get();

    snapshot.docs.forEach((doc) {
      listOfMessages.add(MessageData.fromJson(doc.data()));
    });
    chatModel.messages = listOfMessages;
    chatModel.matchedUser = matchedUser;
    chatModelStreamController.sink.add(chatModel);

    firestore
      .collection(CHANNELS)
        .doc(homeConversationModel.conversationModel.id)
          .collection(THREAD)
            .orderBy('createdAt', descending: true)
              .snapshots()
                .listen((onData) {
      onData.docChanges.forEach((document) {
        listOfMessages.add(MessageData.fromJson(document.doc.data()));
      });
      chatModel.messages = listOfMessages;
      chatModel.matchedUser = matchedUser;
      chatModelStreamController.sink.add(chatModel);
    });

    yield* chatModelStreamController.stream;

  }

  Future<void> sendMessage(AppUser currentUser, AppUser matchedUser, MessageData message, ConversationModel conversationModel, { String notificationText }) async {
    var ref = firestore.collection(CHANNELS).doc(conversationModel.id).collection(THREAD).doc();
    message.messageID = ref.id;
    ref.set(message.toJson(), SetOptions(merge: true));
    await Future.forEach([matchedUser], (AppUser element) async {
      if (element.userID != FirebaseAuth.instance.currentUser.uid && element.settings.pushNewMessages) {
        await sendNotification(
          recipientID: element.userID,
          notificationText: notificationText ?? "${currentUser.userName} sent you a message"
        );
      }
    });
  }

  Future<bool> createConversation(ConversationModel conversation) async {
    bool isSuccessful;
    await firestore
        .collection(CHANNELS)
        .doc(conversation.id)
        .set(conversation.toJson())
        .then((onValue) async {
      ChannelParticipation myChannelParticipation = ChannelParticipation(
        user: FirebaseAuth.instance.currentUser.uid, channel: conversation.id);
      ChannelParticipation myFriendParticipation = ChannelParticipation(
        user: conversation.id.replaceAll(FirebaseAuth.instance.currentUser.uid, '').replaceAll(':', ''),
        channel: conversation.id);
      await createChannelParticipation(myChannelParticipation);
      await createChannelParticipation(myFriendParticipation);
      isSuccessful = true;
    }, onError: (e) {
      print(e);
      isSuccessful = false;
    });
    return isSuccessful;
  }

  Future<void> updateChannel(ConversationModel conversationModel) async {
    await firestore
      .collection(CHANNELS)
      .doc(conversationModel.id)
      .update(conversationModel.toJson());
  }

  Future<void> createChannelParticipation(ChannelParticipation channelParticipation) async {
    await firestore.collection(CHANNEL_PARTICIPATION).add(channelParticipation.toJson());
  }

  Future<bool> blockUser(AppUser blockedUser, String type) async {
    bool isSuccessful = false;
    BlockUserModel blockUserModel = BlockUserModel(
      type: type,
      source: FirebaseAuth.instance.currentUser.uid,
      dest: blockedUser.userID,
      createdAt: Timestamp.now(),
    );
    await firestore
      .collection(REPORTS)
      .add(blockUserModel.toJson())
      .then((onValue) {
        isSuccessful = true;
    });
    return isSuccessful;
  }

  Stream<bool> getBlocks() async* {
    StreamController<bool> refreshStreamController = StreamController();

    firestore.collection(REPORTS)
      .where('source', isEqualTo: FirebaseAuth.instance.currentUser.uid,).
    snapshots().listen((onData) {
      List<BlockUserModel> list = [];
      for (DocumentSnapshot block in onData.docs) {
        list.add(BlockUserModel.fromJson(block.data()));
      }
      blockedList = list;

      if (homeConversations.isNotEmpty || matches.isNotEmpty) {
        refreshStreamController.sink.add(true);
      }
    });

    yield* refreshStreamController.stream;
  }

  bool validateIfUserBlocked(String userID) {
    for (BlockUserModel blockedUser in blockedList) {
      if (userID == blockedUser.dest) {
        return true;
      }
    }
    return false;
  }

  static getFleekUsers(AppUser currentUser, FleekData data) async {

    //print("loading");
    //LocationData locationData = await getCurrentLocation();

    // if (locationData != null) {
    //   currentUser.location = UserLocation(
    //     latitude: locationData.latitude,
    //     longitude: locationData.longitude,
    //   );

      var viewedUsersRef = await firestore.collectionGroup("${currentUser.settings.searchInterest.toFirebaseString()}::VIEWED_USERS_FOR::${currentUser.userID}").get();
      var viewedUsers = List();
      viewedUsersRef.docs.forEach((element) {
        viewedUsers.addAll((element.data()["viewedUserIDs"] as List));
      });

      var query = firestore.collection(USERS)
        .where('showMe', isEqualTo: true) // The person must want to be shown
        .where('developerAccount', isEqualTo: kDebugMode) // and is not a developer account
        .where('settings.genderPreference', whereIn: [currentUser.settings.gender.toFirebaseString(), GenderPreference.ALL.toFirebaseString()]) // and likes people of my gender or all people
        .where('settings.searchInterest', isEqualTo: currentUser.settings.searchInterest.toFirebaseString());

      // If I have a preference, add my preference to the query
      if (currentUser.settings.genderPreference != GenderPreference.ALL) {
        query = query.where('settings.gender', isEqualTo: currentUser.settings.genderPreference.toFirebaseString());
      }

      // geo.collection(collectionRef: query).within(
      //   center: currentUser.location,
      //   radius: currentUser.settings.distanceRadius,
      //   field: 'location',
      // ).listen((value) {

      int skippedUserCount = 0;
      int resultSize = 0;

      StreamSubscription<QuerySnapshot> dataStream;
      dataStream = query.snapshots().listen((value) {

        if (value.docs.isEmpty) {
          data.fetchingData = false;
          dataStream.cancel();
          return;
        }

        for (var fleekUser in value.docs) {

          if (fleekUser.id != FirebaseAuth.instance.currentUser.uid) {
            AppUser user = AppUser.fromJson(fleekUser.data());
            // int distance = getDistance(user.location, currentUser.location).ceil();
            if (!viewedUsers.contains(user.userID) && !data.seenRecently(user, currentUser.settings.searchInterest)) {
              // user.milesAway = '${distance < 3 ? '~2' : distance} Miles Away';
              data.addUser(user, currentUser.settings.searchInterest);
              resultSize += 1;
            } else {
              skippedUserCount += 1;
            }
          } else {
            skippedUserCount += 1;
          }

          if (resultSize >= FleekData.MAX_FETCH_COUNT || resultSize + skippedUserCount == value.docs.length) {
            dataStream.cancel();
            data.fetchingData = false;
            break;
          }

        }

      });

    // }
  }

  matchChecker(BuildContext context) async {
    String myID = FirebaseAuth.instance.currentUser.uid;
    QuerySnapshot result = await firestore
      .collection(SWIPES)
      .where('forUserID', isEqualTo: myID)
      .where('type', isEqualTo: 'like')
      .get();
    if (result.docs.isNotEmpty) {
      await Future.forEach(result.docs, (DocumentSnapshot document) async {
        Swipe match = Swipe.fromJson(document.data());
        QuerySnapshot unSeenMatches = await firestore
          .collection(SWIPES)
          .where('swiperUserID', isEqualTo: myID)
          .where('type', isEqualTo: 'like')
          .where('forUserID', isEqualTo: match.swiperUserID)
          .where('hasBeenSeen', isEqualTo: false)
          .get();
        if (unSeenMatches.docs.isNotEmpty) {
          unSeenMatches.docs.forEach((DocumentSnapshot unSeenMatch) async {
            DocumentSnapshot matchedUserDocSnapshot = await firestore.collection(USERS).doc(match.swiperUserID).get();
            AppUser matchedUser = AppUser.fromJson(matchedUserDocSnapshot.data());
            push(context, MatchScreen(matchedUser: matchedUser));
            updateHasBeenSeen(unSeenMatch.data());
          });
        }
      });
    }
  }

  onSwipeLeft({ @required AppUser currentUser, @required AppUser dislikedUser }) async {
    DocumentReference documentReference = firestore.collection(SWIPES).doc();
    Swipe leftSwipe = Swipe(
      id: documentReference.id,
      type: 'dislike',
      swiperUserID: FirebaseAuth.instance.currentUser.uid,
      forUserID: dislikedUser.userID,
      createdAt: Timestamp.now(),
      hasBeenSeen: false,
      searchInterest: currentUser.settings.searchInterest
    );
    await documentReference.set(leftSwipe.toJson());
  }

  Future<AppUser> onSwipeRight({ @required AppUser currentUser, @required AppUser likedUser }) async {
    // check if this user sent a match request before ? if yes, it's a match,
    // if not, send him match request
    QuerySnapshot querySnapshot = await firestore
      .collection(SWIPES)
      .where('swiperUserID', isEqualTo: likedUser.userID)
      .where('forUserID', isEqualTo: FirebaseAuth.instance.currentUser.uid)
      .where('type', isEqualTo: 'like')
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      //this user sent me a match request, let's talk
      DocumentReference document = firestore.collection(SWIPES).doc();
      var swipe = Swipe(
        id: document.id,
        type: 'like',
        hasBeenSeen: true,
        createdAt: Timestamp.now(),
        swiperUserID: FirebaseAuth.instance.currentUser.uid,
        forUserID: likedUser.userID,
        searchInterest: currentUser.settings.searchInterest
      );
      await document.set(swipe.toJson(), SetOptions(merge: true));
      if (likedUser.settings.pushNewMatchesEnabled) {
        await sendNotification(
          recipientID: likedUser.userID,
          notificationText: "You have a new match",
        );
      }

      return likedUser;
    } else {
      //this user didn't send me a match request, let's send match request
      // and keep swippeing
      await sendSwipeRequest(currentUser: currentUser, likedUser: likedUser);
      return null;
    }
  }

  Future<bool> sendSwipeRequest({ @required AppUser currentUser, @required AppUser likedUser }) async {
    bool isSuccessful;
    DocumentReference documentReference = firestore.collection(SWIPES).doc();
    Swipe swipe = Swipe(
      id: documentReference.id,
      swiperUserID: FirebaseAuth.instance.currentUser.uid,
      forUserID: likedUser.userID,
      hasBeenSeen: false,
      createdAt: Timestamp.now(),
      type: 'like',
      searchInterest: currentUser.settings.searchInterest
    );
    await documentReference.set(swipe.toJson()).then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      isSuccessful = false;
    });
    return isSuccessful;
  }

  updateHasBeenSeen(Map<String, dynamic> target) async {
    target['hasBeenSeen'] = true;
    await firestore.collection(SWIPES).doc(target['id'] ?? '').update(target);
  }

  Future<void> deleteImage(String imageFileUrl) async {
    var fileUrl = Uri.decodeFull(Path.basename(imageFileUrl)).replaceAll(new RegExp(r'(\?alt).*'), '');

    final Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileUrl);
    await firebaseStorageRef.delete();
  }

  static undo(String forUserID, SearchInterest searchInterest) async {
    await firestore
        .collection(SWIPES)
        .where('searchInterest', isEqualTo: searchInterest.toFirebaseString())
        .where('swiperUserID', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .where('forUserID', isEqualTo: forUserID)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        await firestore
          .collection(SWIPES)
          .doc(value.docs.first.id)
          .delete();
      }
    });
  }

  closeFleekStream() {
    if (fleekCardsStreamController != null) {
      fleekCardsStreamController.close();
    }
  }

  void updateCardStream(List<AppUser> data) {
    fleekCardsStreamController.add(data);
  }

  Future<bool> incrementSwipe() async {
    DocumentReference documentReference = firestore.collection(SWIPE_COUNT).doc(FirebaseAuth.instance.currentUser.uid);

    DocumentSnapshot validationDocumentSnapshot = await documentReference.get();

    if (validationDocumentSnapshot != null && validationDocumentSnapshot.exists) {
      // TODO: set max number of swipes when payments are implemented
      if ((validationDocumentSnapshot['count'] ?? 1) < double.infinity) {
        // await firestore.doc(documentReference.path).update({'count': validationDocumentSnapshot['count'] + 1});
        return true;
      } else {
        return _shouldResetCounter(validationDocumentSnapshot);
      }
    } else {
      await firestore.doc(documentReference.path).set(SwipeCounter(
        authorID: FirebaseAuth.instance.currentUser.uid,
        createdAt: Timestamp.now(),
        count: 1,
      ).toJson());
      return true;
    }

  }

  Future<Url> uploadAudioFile(file, BuildContext context) async {

    showProgress(context, 'Uploading Audio...', false);

    var uniqueID = Uuid().v4();
    Reference upload = storage.child("audio/$uniqueID.mp3");
    UploadTask uploadTask = upload.putFile(file);

    uploadTask.snapshotEvents.listen((event) {
      updateProgress(
        'Uploading image ${(event.bytesTransferred.toDouble() / 1000)
        .toStringAsFixed(2)} /'
        '${(event.totalBytes.toDouble() / 1000)
        .toStringAsFixed(2)} '
        'KB'
      );
    });

    await uploadTask;
    Navigator.of(context).pop();

    String url = await uploadTask.snapshot.ref.getDownloadURL();
    return Url(
      mime: "audio/aac",
      url: url,
    );

  }

  Future<bool> _shouldResetCounter(DocumentSnapshot documentSnapshot) async {
    SwipeCounter counter = SwipeCounter.fromJson(documentSnapshot.data());
    DateTime now = DateTime.now();
    DateTime from = DateTime.fromMillisecondsSinceEpoch(counter.createdAt.millisecondsSinceEpoch);
    Duration diff = now.difference(from);
    if (diff.inDays > 0) {
      counter.count = 1;
      counter.createdAt = Timestamp.now();
      await firestore.collection(SWIPE_COUNT).doc(counter.authorID).update(counter.toJson());
      return true;
    } else {
      return false;
    }
  }

}

sendNotification({ @required String recipientID, @required String notificationText, String notificationTitle = "Fleek" }) async {
  HttpsCallable sendNotificationFunc = FirebaseFunctions.instance.httpsCallable('sendNotification');
  sendNotificationFunc.call<Map<String, String>>({
    "recipient_id": recipientID,
    "notification_text": notificationText,
    "notification_title": notificationText
  }).catchError((e) {
    throw e;
  });
}
