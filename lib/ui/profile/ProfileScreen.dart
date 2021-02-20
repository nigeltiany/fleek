import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/ProfileImagePicker.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';


class ProfileScreen extends StatefulWidget {

  ProfileScreen({Key key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();

}

class _ProfileScreenState extends State<ProfileScreen> {

  final ImagePicker _imagePicker = ImagePicker();
  AppUser user;
  final _currentPageNotifier = ValueNotifier<int>(0);

  _ProfileScreenState();

  List images = List();
  List _pages = [];
  List<Widget> _gridPages = [];

  TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    user = context.read<AppUser>();
    _bioController = TextEditingController();
    _bioController.text = user.bio;
    images.clear();
    images.addAll(user.photos);
    if (images.isNotEmpty) {
      if (images[images.length - 1] != null) {
        images.add(null);
      }
    } else {
      images.add(null);
    }
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gridPages = _buildGridView();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Center(child: ProfileImagePicker()),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 32, left: 32),
            child: SizedBox(
              width: double.infinity,
              child: Text(user.userName ?? "",
                style: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: skipNulls([
                Text('My Photos',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _pages.length >= 2 ?
                CirclePageIndicator(
                  selectedDotColor: Color(COLOR_ACCENT),
                  dotColor: Colors.grey,
                  itemCount: _pages.length,
                  currentPageNotifier: _currentPageNotifier,
                )
                :
                null
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: SizedBox(
              height: user.photos.length > 3 ? 260 : 130,
              width: double.infinity,
              child: PageView(
                children: _gridPages,
                onPageChanged: (int index) {
                  _currentPageNotifier.value = index;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 16),
            child: ListTile(
              title: ListTile(
                title: Text('My Bio',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  padding: EdgeInsets.all(4),
                  splashRadius: 24,
                  onPressed: () {
                    _showBioEditor(context);
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
              isThreeLine: true,
              subtitle: Text(user.bio ?? ""),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _imageBuilder(String url) {
    bool isLastItem = url == null;

    return GestureDetector(
      onTap: () {
        isLastItem ? _pickImage() : _viewOrDeleteImage(url);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        color: Color(COLOR_PRIMARY),
        child: isLastItem
            ? Icon(
          Icons.camera_alt,
          size: 50,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl:
            user.profilePictureURL == DEFAULT_AVATAR_URL ? '' : url,
            placeholder: (context, imageUrl) {
              return Icon(
                Icons.hourglass_empty,
                size: 75,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              );
            },
            errorWidget: (context, imageUrl, error) {
              return Icon(
                Icons.error_outline,
                size: 75,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGridView() {
    _pages.clear();
    List<Widget> gridViewPages = [];
    var len = images.length;
    var size = 6;
    for (var i = 0; i < len; i += size) {
      var end = (i + size < len) ? i + size : len;
      _pages.add(images.sublist(i, end));
    }
    _pages.forEach((elements) {
      gridViewPages.add(
        GridView.builder(
          padding: EdgeInsets.only(right: 16, left: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _imageBuilder(elements[index]),
          itemCount: elements.length,
          physics: BouncingScrollPhysics(),
        ),
      );
    });
    return gridViewPages;
  }

  _viewOrDeleteImage(String url) {

    final removePicture = () async {
      Navigator.pop(context);
      images.removeLast();
      images.remove(url);
      await FireStoreUtils.deleteImage(url);
      user.photos = images;
      AppUser updatedUser = await FireStoreUtils.updateCurrentUser(user);
      context.read<AppUser>().copy(updatedUser);
      user = updatedUser;
      images.add(null);
      setState(() {});
    };

    final makeProfilePicture = () async {
      Navigator.pop(context);
      var data = await FirebaseStorage.instance.refFromURL(url).getData();
      String dir = (await getTemporaryDirectory()).path;
      File tempFile = File('$dir/picture_switch');
      await tempFile.writeAsBytes(data);
      var newURL = await FireStoreUtils.uploadUserImageToFireStorage(user, tempFile, ImageType.DISPLAY_PIC);
      await tempFile.delete();
      user.profilePictureURL = newURL;
      user = await FireStoreUtils.updateCurrentUser(user);
      context.read<AppUser>().copy(user);
      setState(() {});
    };

    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            push(context, FullScreenImageViewer(image: NetworkImage(url), tag: url));
          },
          isDefaultAction: true,
          child: Text("View Picture"),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            await makeProfilePicture();
          },
          isDefaultAction: true,
          child: Text("Make Profile Picture"),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            await removePicture();
          },
          child: Text("Remove Picture"),
          isDestructiveAction: true,
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );

    final androidAction = BottomSheet(
      backgroundColor: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
      enableDrag: false,
      onClosing: () {},
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text("View Picture"),
              onTap: () async {
                Navigator.pop(context);
                push(context, FullScreenImageViewer(image: NetworkImage(url), tag: url));
              },
            ),
            ListTile(
              title: Text("Make Profile Picture"),
              onTap: () async {
                await makeProfilePicture();
              },
            ),
            ListTile(
              title: Text("Remove Picture",
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              onTap: () async {
                await removePicture();
              },
            ),
            SizedBox(height: 16)
          ],
        );
      },
    );

    if (Platform.isIOS) {
      showCupertinoModalPopup(context: context, builder: (context) => action);
    } else {
      showModalBottomSheet(context: context, builder: (context) => androidAction);
    }

  }

  _pickImage() {

    final imageFromGallery = () async {
      Navigator.pop(context);
      PickedFile image = await _imagePicker.getImage(source: ImageSource.gallery);
      if (image != null) {
        String imageUrl = await FireStoreUtils.uploadUserImageToFireStorage(user, File(image.path), ImageType.ACCOUNT_PIC);
        images.removeLast();
        images.add(imageUrl);
        user.photos = images;
        AppUser updatedUser = await FireStoreUtils.updateCurrentUser(user);
        context.read<AppUser>().copy(updatedUser);
        user = updatedUser;
        images.add(null);
        setState(() {});
      }
    };

    final imageFromCamera = () async {
      Navigator.pop(context);
      PickedFile image = await _imagePicker.getImage(source: ImageSource.camera);
      if (image != null) {
        String imageUrl = await FireStoreUtils.uploadUserImageToFireStorage(user, File(image.path), ImageType.ACCOUNT_PIC);
        images.removeLast();
        images.add(imageUrl);
        user.photos = images;
        AppUser updatedUser = await FireStoreUtils.updateCurrentUser(user);
        context.read<AppUser>().copy(updatedUser);
        user = updatedUser;
        images.add(null);
        setState(() {});
      }
    };

    final action = CupertinoActionSheet(
      message: Text("Add picture",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Choose from gallery"),
          isDefaultAction: false,
          onPressed: () async {
            await imageFromGallery();
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          isDestructiveAction: false,
          onPressed: () async {
            await imageFromCamera();
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
      backgroundColor: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
      enableDrag: false,
      onClosing: () {},
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text("Add Picture",
                style: TextStyle(
                  color:  Color(COLOR_PRIMARY_DARK),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () async {
                await imageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Gallery"),
              onTap: () async {
                await imageFromGallery();
              },
            ),
            SizedBox(height: 16)
          ],
        );
      },
    );

    if (Platform.isIOS) {
      showCupertinoModalPopup(context: context, builder: (context) => action);
    } else {
      showModalBottomSheet(context: context, builder: (context) => androidAction);
    }

  }

  _showBioEditor(BuildContext ctx) {
    final preferredHeight = AppBar().preferredSize.height;
    showModalBottomSheet(
      context: ctx,
      enableDrag: false,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.only(
                        top: preferredHeight,
                        left: 16,
                        right: 16,
                      ),
                      tileColor: Color(COLOR_PRIMARY_DARK),
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      title: Text("Bio",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          user.bio = _bioController.text;
                          await FireStoreUtils.updateCurrentUser(user);
                          _bioController.text = "";
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Positioned(
                      width: MediaQuery.of(context).size.width,
                      top: preferredHeight * 2,
                      bottom: 0,
                      child: SingleChildScrollView(
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 0.0), // content padding
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: TextField(
                                    autofocus: true,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    controller: _bioController,
                                  ),
                                ),
                              ],
                            ),
                          ), // From with TextField inside
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

}
