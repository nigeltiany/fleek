class UserLocation {
  num latitude = 00.1;
  num longitude = 00.1;

  UserLocation({this.latitude, this.longitude});

  factory UserLocation.fromJson(Map<dynamic, dynamic> parsedJson) {
    return new UserLocation(
      latitude: parsedJson['latitude'] ?? 00.1,
      longitude: parsedJson['longitude'] ?? 00.1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': this.latitude,
      'longitude': this.longitude,
    };
  }
}
