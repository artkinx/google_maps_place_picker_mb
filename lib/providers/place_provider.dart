import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/src/models/pick_result.dart';
import 'package:google_maps_place_picker_mb/src/place_picker.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../src/models/circle_area.dart';

class PlaceProvider extends ChangeNotifier {
  PlaceProvider(
    String apiKey,
    String? proxyBaseUrl,
    Client? httpClient,
    Map<String, dynamic> apiHeaders,
  ) {
    places = GoogleMapsPlaces(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );

    geocoding = GoogleMapsGeocoding(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
  }

  static PlaceProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<PlaceProvider>(context, listen: listen);

  late GoogleMapsPlaces places;
  late GoogleMapsGeocoding geocoding;
  String? sessionToken;
  bool isOnUpdateLocationCooldown = false;
  LocationAccuracy? desiredAccuracy;
  bool isAutoCompleteSearching = false;
  CircleArea? searchRadiusArea;

  LocationPlatformInterface.Location location =
      new LocationPlatformInterface.Location();
  LocationPlatformInterface.PermissionStatus permissionGranted =
      LocationPlatformInterface.PermissionStatus.denied;
  bool isLocationServiceEnabled = false;

  Future<void> updateCurrentLocation(bool forceAndroidLocationManager) async {
    isLocationServiceEnabled = await location.serviceEnabled();
    if (!isLocationServiceEnabled) {
      // isLocationServiceEnabled = await location.requestService();
      if (!isLocationServiceEnabled) {
        // Get.dialog(
        //   Padding(
        //     padding: const EdgeInsets.all(10.0),
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       crossAxisAlignment: CrossAxisAlignment.center,
        //       children: [
        //         const Icon(Icons.location_disabled),
        //         const SizedBox(
        //           height: 10,
        //         ),
        //         const Text(
        //             "Your location service seems to be deisabled. Please enable your Location service and Click/Tap the Continue button."),
        //         const SizedBox(
        //           height: 20,
        //         ),
        //         ElevatedButton(
        //           onPressed: () async {
        //             await requestPermission().whenComplete(() => Get.back());
        //           },
        //           child: const Text("Continue"),
        //         ),
        //       ],
        //     ),
        //   ),
        // );
        // return;
      }
    }

    await requestPermission();
    notifyListeners();
  }

  Future<void> requestPermission() async {
    permissionGranted = await location.hasPermission();
    try {
      permissionGranted = await location.requestPermission();
      if (permissionGranted ==
          LocationPlatformInterface.PermissionStatus.granted) {
        currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy ?? LocationAccuracy.best);
      } else {
        currentPosition = null;
      }
    }
  }

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;
  set currentPosition(Position? newPosition) {
    _currentPosition = newPosition;
    notifyListeners();
  }

  Timer? _debounceTimer;
  Timer? get debounceTimer => _debounceTimer;
  set debounceTimer(Timer? timer) {
    _debounceTimer = timer;
    notifyListeners();
  }

  CameraPosition? _previousCameraPosition;
  CameraPosition? get prevCameraPosition => _previousCameraPosition;
  setPrevCameraPosition(CameraPosition? prePosition) {
    _previousCameraPosition = prePosition;
  }

  CameraPosition? _currentCameraPosition;
  CameraPosition? get cameraPosition => _currentCameraPosition;
  setCameraPosition(CameraPosition? newPosition) {
    _currentCameraPosition = newPosition;
  }

  PickResult? _selectedPlace;
  PickResult? get selectedPlace => _selectedPlace;
  set selectedPlace(PickResult? result) {
    _selectedPlace = result;

    if (SearchRadius > 0)
      searchRadiusArea = CircleArea(
          center: _currentCameraPosition!.target, radius: SearchRadius);
    notifyListeners();
  }

  SearchingState _placeSearchingState = SearchingState.Idle;
  SearchingState get placeSearchingState => _placeSearchingState;
  set placeSearchingState(SearchingState newState) {
    _placeSearchingState = newState;
    notifyListeners();
  }

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;
  set mapController(GoogleMapController? controller) {
    _mapController = controller;
    notifyListeners();
  }

  PinState _pinState = PinState.Preparing;
  PinState get pinState => _pinState;
  set pinState(PinState newState) {
    _pinState = newState;
    notifyListeners();
  }

  bool _isSeachBarFocused = false;
  bool get isSearchBarFocused => _isSeachBarFocused;
  set isSearchBarFocused(bool focused) {
    _isSeachBarFocused = focused;
    notifyListeners();
  }

  double _searchRadius = 0;
  double get SearchRadius => _searchRadius;
  set Searchradius(double rad) {
    _searchRadius = rad;
    notifyListeners();
  }

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;
  setMapType(MapType mapType, {bool notify = false}) {
    _mapType = mapType;
    if (notify) notifyListeners();
  }

  switchMapType() {
    _mapType = MapType.values[(_mapType.index + 1) % MapType.values.length];
    if (_mapType == MapType.none) _mapType = MapType.normal;

    notifyListeners();
  }
}
