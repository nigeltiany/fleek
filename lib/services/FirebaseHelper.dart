import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ChatVideoContainer.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/Gender.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/model/SwipeCounterModel.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/Data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:path/path.dart' as Path;
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';



final geo = Geoflutterfire();

enum ImageType {
  DISPLAY_PIC,
  ACCOUNT_PIC
}

class FireStoreUtils {

  static FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static Reference storage = FirebaseStorage.instance.ref();

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

  static String _getFileExtension(File file) {
    return file.path == null ? "" : Path.extension(file.path);
  }

  static Future<String> uploadUserImageToFireStorage(AppUser user, File image, ImageType imageType) async {

    if (FirebaseAuth.instance.currentUser == null) return null;

    if (user.profilePictureURL != null && user.profilePictureURL.isNotEmpty && imageType == ImageType.DISPLAY_PIC) {
      try {
        await FirebaseStorage.instance.refFromURL(user.profilePictureURL).delete();
      } catch (e) {

      }
    }

    String userID = FirebaseAuth.instance.currentUser.uid;
    String userPath = base64Url.encode(Uuid().v5(Uuid().v5(Uuid.NAMESPACE_URL, userID), userID).codeUnits);

    String location;
    if (imageType == ImageType.DISPLAY_PIC) {
      location = "user_profile_picture/$userPath${_getFileExtension(image)}";
    } else {
      location = "user_pictures/$userPath/${base64Url.encode(Uuid().v4().codeUnits)}${_getFileExtension(image)}";
    }

    Reference upload = storage.child(location);
    UploadTask uploadTask = upload.putFile(image);

    await uploadTask;

    return await uploadTask.snapshot.ref.getDownloadURL();

  }

  static Future<String> uploadChatImageToFireStorage(BuildContext context, File image, String conversationID) async {

    showProgress(context, 'Uploading image...', false);

    var uniqueID = Uuid().v4();
    Reference upload = storage.child("conversation_images/${conversationID.replaceAll(USER_ID_DELIMITER, "-u0u-")}/$uniqueID${_getFileExtension(image)}");
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

  // Future<ChatVideoContainer> uploadChatVideoToFireStorage(video, BuildContext context) async {
  //   showProgress(context, 'Uploading video...', false);
  //   var uniqueID = Uuid().v4();
  //   Reference upload = storage.child("videos/$uniqueID.mp4");
  //   SettableMetadata metadata = new SettableMetadata(contentType: 'video');
  //   UploadTask uploadTask = upload.putFile(video, metadata);
  //   uploadTask.events.listen((event) {
  //     updateProgress(
  //         'Uploading video ${(event.snapshot.bytesTransferred.toDouble() / 1000)
  //             .toStringAsFixed(2)} /'
  //             '${(event.snapshot.totalByteCount.toDouble() / 1000)
  //             .toStringAsFixed(2)} '
  //             'KB');
  //   });
  //   var storageRef = (await uploadTask.onComplete).ref;
  //   var downloadUrl = await storageRef.getDownloadURL();
  //   var metaData = await storageRef.getMetadata();
  //   final uint8list = await VideoThumbnail.thumbnailFile(
  //       video: downloadUrl,
  //       thumbnailPath: (await getTemporaryDirectory()).path,
  //       imageFormat: ImageFormat.PNG);
  //   final file = File(uint8list);
  //   String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
  //   Navigator.of(context).pop(); // Close Dialog
  //   return ChatVideoContainer(
  //       videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType),
  //       thumbnailUrl: thumbnailDownloadUrl);
  // }

  static Future<String> uploadVideoThumbnailToFireStorage(file) async {
    // var uniqueID = Uuid().v4();
    // Reference upload = storage.child("thumbnails/$uniqueID.png");
    // UploadTask uploadTask = upload.putFile(file);
    // var downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    // return downloadUrl.toString();
  }

  static Stream<AppUser> getUserByIDStream(String id) async* {
    StreamController<AppUser> userStreamController = StreamController();
    firestore.collection(USERS).doc(id).snapshots().listen((user) {
      if (user.data != null) {
        userStreamController.sink.add(AppUser.fromJson(user.data()));
      }
    });
    yield* userStreamController.stream;
  }

  static Future<AppUser> getUserByID(String id) async {
    var userSnapshot = await firestore.collection(USERS).doc(id).get();
    if (!userSnapshot.exists) {
      return null;
    }
    return AppUser.fromJson(userSnapshot.data());
  }

  static Future<void> sendMessage(AppUser currentUser, AppUser matchedUser, MessageData message, { String notificationText }) async {
    var ref = firestore.collection(MATCH_CONVERSATIONS).doc(normalizedConversationID(currentUser.userID, matchedUser.userID)).collection(CONVERSATION_MESSAGES).doc();
    message.messageID = ref.id;
    await ref.set(message.toJson(), SetOptions(merge: true));
  }

  static Future<void> updateChannel(ConversationModel conversationModel) async {
    await firestore.collection(MATCH_CONVERSATIONS).doc(conversationModel.id).set(conversationModel.toJson(), SetOptions(merge: true));
  }

  static Future<bool> blockUser(IdentifiableUser user) async {

    bool isSuccessful = false;

    await firestore.collection(MATCH_CONVERSATIONS)
      .doc(normalizedConversationID(FirebaseAuth.instance.currentUser.uid, user.userID))
      .delete();

    await firestore.collection(MATCHES)
      .doc(FirebaseAuth.instance.currentUser.uid)
      .collection('matches')
      .doc(user.userID)
      .delete();

    await firestore.collection(USERS).doc(FirebaseAuth.instance.currentUser.uid).set({
      "blockList": FieldValue.arrayUnion([user.userID])
    }, SetOptions(merge: true)).then((document) {
      isSuccessful = true;
    });

    return isSuccessful;

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
        .where('settings.showMe', isEqualTo: true) // The person must want to be shown
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
            if (user.blockList.contains(currentUser.userID) || currentUser.blockList.contains(user.userID)) {
              skippedUserCount += 1;
            } else if (!viewedUsers.contains(user.userID) && !data.seenRecently(user, currentUser.settings.searchInterest)) {
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

  static onSwipeLeft({ @required AppUser currentUser, @required AppUser dislikedUser }) async {
    DocumentReference documentReference = firestore.collection(SWIPES).doc();
    Swipe leftSwipe = Swipe(
      id: documentReference.id,
      type: SwipeType.PASS,
      swiper: SwipeSubject.fromUser(currentUser),
      subject: SwipeSubject.fromUser(dislikedUser),
      createdAt: Timestamp.now(),
      hasBeenSeen: false,
      searchInterest: currentUser.settings.searchInterest
    );
    await documentReference.set(leftSwipe.toJson());
  }

  static Future<bool> onSwipeRight({ @required AppUser currentUser, @required AppUser likedUser, bool superLike = false }) async {
    bool isSuccessful;
    DocumentReference documentReference = firestore.collection(SWIPES).doc();
    Swipe swipe = Swipe(
      id: documentReference.id,
      swiper: SwipeSubject.fromUser(currentUser),
      subject: SwipeSubject.fromUser(likedUser),
      hasBeenSeen: false,
      createdAt: Timestamp.now(),
      type: superLike ? SwipeType.SUPER_LIKE : SwipeType.LIKE,
      searchInterest: currentUser.settings.searchInterest
    );
    await documentReference.set(swipe.toJson()).then((onValue) {
      isSuccessful = true;
    }, onError: (e) {
      isSuccessful = false;
    });
    return isSuccessful;
  }

  static Future<void> deleteImage(String imageFileUrl) async {
    var fileUrl = Uri.decodeFull(Path.basename(imageFileUrl)).replaceAll(new RegExp(r'(\?alt).*'), '');

    final Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileUrl);
    await firebaseStorageRef.delete();
  }

  static undo(String forUserID, SearchInterest searchInterest) async {
    await firestore
        .collection(SWIPES)
        .where('searchInterest', isEqualTo: searchInterest.toFirebaseString())
        .where('swiper.id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .where('subject.id', isEqualTo: forUserID)
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

  static Future<bool> incrementSwipe() async {
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

  static Future<Url> uploadAudioFile(file, BuildContext context) async {

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

  static Future<bool> _shouldResetCounter(DocumentSnapshot documentSnapshot) async {
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
