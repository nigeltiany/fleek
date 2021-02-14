import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatelessWidget {
  final ImageProvider image;
  final String tag;

  const FullScreenImageViewer({Key key, @required this.image, @required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        elevation: 0.0,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.black,
        child: Hero(
          tag: tag,
          child: PhotoView(
            imageProvider: image,
          ),
        ),
      ),
    );
  }
}
