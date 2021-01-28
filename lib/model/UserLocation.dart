import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class UserLocation implements GeoFirePoint {

  GeoFirePoint _point;

  UserLocation({
    double latitude = 0,
    double longitude = 0,
  }) {
    _point = Geoflutterfire().point(latitude: latitude, longitude: longitude);
  }

  factory UserLocation.fromJson(Map<dynamic, dynamic> parsedJson) {
    if (!parsedJson.containsKey('geopoint')) {
      return UserLocation(latitude: 0, longitude: 0);
    }

    var point = parsedJson['geopoint'] as GeoPoint;

    return UserLocation(
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return this._point.data;
  }

  @override
  double get latitude => _point.latitude;

  @override
  double get longitude => _point.longitude;

  @override
  void set latitude(double _latitude) {
    _point.latitude = _latitude;
  }

  @override
  void set longitude(double _longitude) {
    _point.longitude = _longitude;
  }

  @override
  // TODO: implement coords
  Coordinates get coords => _point.coords;

  @override
  // TODO: implement data
  get data => _point.data;

  @override
  double distance({double lat, double lng}) {
    return _point.distance(lat: lat, lng: lng);
  }

  @override
  // TODO: implement geoPoint
  GeoPoint get geoPoint => _point.geoPoint;

  @override
  // TODO: implement hash
  String get hash => _point.hash;

  @override
  haversineDistance({double lat, double lng}) {
    return _point.haversineDistance(lat: lat, lng: lng);
  }

  @override
  // TODO: implement neighbors
  List<String> get neighbors => _point.neighbors;

}
