import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class AllowLocationServices extends StatefulWidget {

  final PageController pageController;

  const AllowLocationServices({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  _AllowLocationServicesState createState() => _AllowLocationServicesState(pageController);

}

class _AllowLocationServicesState extends State<AllowLocationServices> {

  final PageController pageController;
  Location location;
  bool _locationReady = false;

  _AllowLocationServicesState(this.pageController);

  @override
  void initState() {
    super.initState();
    location = Location();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: isDarkMode(context) ? Colors.black : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _title(),
              Spacer(),
              _enableLocationButton(),
              Spacer(),
              _nextScreenButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location Settings',
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12),
            Text(_locationReady ? 'All set! We will show you matches close to you.' : 'Almost there! Enable location services to get people matches you.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationEnabled () {
    return Center(
      child: Icon(
        Icons.check_circle,
        color: Color(COLOR_PRIMARY),
        size: 72,
      ),
    );
  }

  Widget _locationDisabled() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: SecondaryButton(
          label: "Enable Location",
          onTap: () async {
            bool _serviceEnabled = await location.requestService();
            if (_serviceEnabled) {
              setState(() => _locationReady = true);
            }
          },
        ),
      ),
    );
  }

  Widget _enableLocationButton () {
    return FutureBuilder(
      future: location.serviceEnabled(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data) {
            if (!_locationReady) {
              SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
                _locationReady = true;
              }));
            }
            return _locationEnabled();
          }
          return _locationDisabled();
        } else if (snapshot.hasError) {
          return _locationDisabled();
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _nextScreenButton () {
    if (!_locationReady) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Continue",
          onTap: () async {
            var user = context.read<AppUser>();
            var locationData = await location.getLocation();
            var loc = UserLocation(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
            );
            user.location = loc;
            user.signUpLocation = loc;
            user.active = true;
            user.settings.showMe = true;
            await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
          },
        ),
      ),
    );
  }

}
