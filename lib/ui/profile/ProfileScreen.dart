import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/ProfileImagePicker.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

class ProfileScreen extends StatefulWidget {

  ProfileScreen({Key key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();

}

class _ProfileScreenState extends State<ProfileScreen> {

  final ImagePicker _imagePicker = ImagePicker();
  AppUser user;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  final _currentPageNotifier = ValueNotifier<int>(0);

  _ProfileScreenState();

  List images = List();
  List _pages = [];
  List<Widget> _gridPages = [];

  @override
  void initState() {
    user = context.read<AppUser>();
    images.clear();
    images.addAll(user.photos);
    if (images.isNotEmpty) {
      if (images[images.length - 1] != null) {
        images.add(null);
      }
    } else {
      images.add(null);
    }
    super.initState();
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
              child: Text(user.userName,
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
                Text(
                  'My Photos',
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
                    // TODO: Open modal to edit bio
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
              isThreeLine: true,
              subtitle: Text("lorem fj  jek n flkan k nfleak nl naelk fla eknalefkna aekn ken alekn nalke n knalek n knleak nk nlaekn lna lakne nlaken nalekn nlaekn k nalek n nlakn lkae akne kan lkaen lkaen lkenfk nel n"),
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
      gridViewPages.add(GridView.builder(
          padding: EdgeInsets.only(right: 16, left: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemBuilder: (context, index) => _imageBuilder(elements[index]),
          itemCount: elements.length,
          physics: BouncingScrollPhysics()));
    });
    return gridViewPages;
  }

  _viewOrDeleteImage(String url) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(context);
            images.removeLast();
            images.remove(url);
            await _fireStoreUtils.deleteImage(url);
            user.photos = images;
            AppUser newUser = await FireStoreUtils.updateCurrentUser(user);
            context.read<AppUser>().copy(newUser);
            user = newUser;
            images.add(null);
            setState(() {});
          },
          child: Text("Remove Picture"),
          isDestructiveAction: true,
        ),
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
            Navigator.pop(context);
            user.profilePictureURL = url;
            user = await FireStoreUtils.updateCurrentUser(user);
            setState(() {});
          },
          isDefaultAction: true,
          child: Text("Make Profile Picture"),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _pickImage() {
    final action = CupertinoActionSheet(
      message: Text(
        "Add picture",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Choose from gallery"),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
            await _imagePicker.getImage(source: ImageSource.gallery);
            if (image != null) {
              String imageUrl = await _fireStoreUtils.uploadChatImageToFireStorage(File(image.path), context);
              images.removeLast();
              images.add(imageUrl);
              user.photos = images;
              AppUser newUser = await FireStoreUtils.updateCurrentUser(user);
              context.read<AppUser>().copy(newUser);
              user = newUser;
              images.add(null);
              setState(() {});
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
            await _imagePicker.getImage(source: ImageSource.camera);
            if (image != null) {
              String imageUrl = await _fireStoreUtils.uploadChatImageToFireStorage(File(image.path), context);
              images.removeLast();
              images.add(imageUrl);
              user.photos = images;
              AppUser newUser = await FireStoreUtils.updateCurrentUser(user);
              context.read<AppUser>().copy(newUser);
              user = newUser;
              images.add(null);
              setState(() {});
            }
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
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    super.dispose();
  }
}
