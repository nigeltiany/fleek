import 'dart:io';

import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatefulWidget {
  @override
  _ProfileImagePickerState createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {

  final ImagePicker _imagePicker = ImagePicker();
  UploadTask _uploadTask;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if (Platform.isAndroid) {
      retrieveLostData();
    }

    return Padding(
      padding:
      const EdgeInsets.only(left: 8.0, top: 32, right: 8, bottom: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.grey.shade400,
            child: ClipOval(
              child: SizedBox(
                width: 170,
                height: 170,
                child: _userProfileState(),
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 0,
            child: FloatingActionButton(
              backgroundColor: Color(COLOR_ACCENT),
              child: Icon(
                Icons.camera_alt,
                color:
                isDarkMode(context) ? Colors.black : Colors.white,
              ),
              mini: true,
              onPressed: _onCameraClick
            ),
          )
        ],
      ),
    );
  }

  Widget _userProfileState() {
    return Consumer<AppUser>(
      builder: (BuildContext context, user, _) {
        return user.profilePictureURL == null || user.profilePictureURL.isEmpty ?
        Image.asset(
          'assets/images/placeholder.jpg',
          fit: BoxFit.cover,
        ) : Image.network(
          user.profilePictureURL,
          fit: BoxFit.cover,
        );
      },
    );
  }

  _onCameraClick() {

    final iosAction = CupertinoActionSheet(
      message: Text(
        "Add profile picture",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Choose from gallery"),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image = await _imagePicker.getImage(source: ImageSource.gallery);
            if (image == null) return;
            await _imagePicked(File(image.path));
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image = await _imagePicker.getImage(source: ImageSource.camera);
            if (image == null) return;
            await _imagePicked(File(image.path));
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );

    final androidAction = BottomSheet(
      enableDrag: false,
      onClosing: () {},
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text("Add Profile Picture")),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () async {
                Navigator.pop(context);
                PickedFile image = await _imagePicker.getImage(source: ImageSource.camera);
                if (image == null) return;
                await _imagePicked(File(image.path));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Gallery"),
              onTap: () async {
                Navigator.pop(context);
                PickedFile image = await _imagePicker.getImage(source: ImageSource.gallery);
                if (image == null) return;
                await _imagePicked(File(image.path));
              },
            ),
            SizedBox(height: 16)
          ],
        );
      },
    );

    if (Platform.isIOS) {
      showCupertinoModalPopup(context: context, builder: (context) => iosAction);
    } else {
      showModalBottomSheet(context: context, builder: (context) => androidAction);
    }
  }

  _imagePicked(File image) async {
    showProgress(context, 'Uploading image...', false);
    AppUser user = context.read<AppUser>();
    String url = await FireStoreUtils().uploadUserImageToFireStorage(
      user,
      image,
      FirebaseAuth.instance.currentUser.uid
    );
    user.profilePictureURL = url;
    FireStoreUtils.updateCurrentUser(user);
    Navigator.of(context).pop(); // Close Dialog
  }

  Future<void> retrieveLostData() async {
    final LostData response = await _imagePicker.getLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      print("lost data");
      print(response.file.path);
    }
  }

}

