import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/driver/rider_main_screen/riderMainScreen.dart';
import 'package:flutter_try_thesis/models/api_json_management/autocomplete_prediction.dart';
import 'package:flutter_try_thesis/models/api_json_management/googleMapApis.dart';
import 'package:flutter_try_thesis/models/firestore_operations/firestoreOperations.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/bookingHistoryCacheModel.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/sqliteOperations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class BookingProvider extends ChangeNotifier {
  //need to add sharedprefs to load cache booking info
  List<LatLng> bookingPolyline = [];
  Map<String, List<LatLng>> BookingPolylineList = {};
  Map<String, dynamic> bookingUserInfo = {};
  bool isBookingButtonAvailable = false;
  bool isBookingAvailable = false;
  String pickupLocation = '';
  String dropoffLocation = '';
  String polylineCode = '';
  LatLng? pickupLatLng;
  LatLng? dropoffLatLng;
  String pinAddress1 = '';
  String pinAddress2 = '';
  LatLng? pinLatLng;
  Set<Marker> pinnedMarkers = {};
  List<String> userReferenceID = [];
  List<Map<String, dynamic>> userValues = [];
  String notes = '';
  String passengerCount = '';
  String zoneRef = '';
  int price = 0;
  Map<String, dynamic> driverInfoForBooking = {};
  double queuePosition = 0;
//Rider
  List<Map<String, dynamic>> values = [];
  List<String> documentID = [];
  late DirectionsClass directions;
  RiderMapState riderState = RiderMapState();
  String currentTerminal = '';
  String queueID = '';
  FirestoreOperations firestoreOperations = FirestoreOperations();
  Map<String, dynamic> transactionDatabasePath = {};
  BookingProvider() {
    directions = DirectionsClass(this);
  }
  void addToPolylineList(LatLng coordinates) {
    bookingPolyline.add(coordinates);
    notifyListeners();
  }

  void updateTerminal(String terminal) {
    currentTerminal = terminal;
    notifyListeners();
  }

  void updateQueueID(String id) {
    queueID = id;
    notifyListeners();
  }

  void bookingAvailable(bool value) {
    isBookingAvailable = value;
    notifyListeners();
  }

  void updatePrice(int newPrice) {
    price = newPrice;
    notifyListeners();
  }

  Marker generateMarker(String id, LatLng coordinates) {
    return Marker(
      markerId: MarkerId(id),
      position: coordinates,
    );
  }

  void updatePickup(String updatedLocation, LatLng coordinates) {
    pickupLocation = updatedLocation;
    pickupLatLng = coordinates;
    addToPinnedMarkers(
      generateMarker('Pickup Pin', coordinates),
    );
    notifyListeners();
  }

  void updateDropoff(String updatedLocation, LatLng coordinates) {
    dropoffLocation = updatedLocation;
    dropoffLatLng = coordinates;
    addToPinnedMarkers(
      generateMarker('Dropoff Pin', coordinates),
    );
    notifyListeners();
  }

  void updateZone(String zone) {
    zoneRef = zone;
    notifyListeners();
  }

  void disableButton() {
    isBookingButtonAvailable = false;
    notifyListeners();
  }

  void updatePinAddress(String address1, String address2, LatLng coordinates) {
    pinAddress1 = address1;
    pinAddress2 = address2;
    pinLatLng = coordinates;
    isBookingButtonAvailable = true;
    notifyListeners();
  }

  void resetBookingInfo({bool resetPickup = false, bool resetDropoff = false}) {
    if (resetPickup) {
      pickupLocation = '';
      pickupLatLng = null;
    } else if (resetDropoff) {
      dropoffLocation = '';
      dropoffLatLng = null;
    } else {
      pickupLocation = '';
      pickupLatLng = null;
      dropoffLocation = '';
      dropoffLatLng = null;
    }
    price = 0;
    bookingPolyline.clear();
    pinnedMarkers.clear();
    notifyListeners();
  }

  void resetPolyline() {
    bookingPolyline.clear();
    notifyListeners();
  }

  void addPolylineListToPolyline(List<LatLng> polyline) {
    bookingPolyline = polyline;
    notifyListeners();
  }

  void addToPinnedMarkers(Marker marker) {
    pinnedMarkers.add(marker);
    notifyListeners();
  }

  void removeMarker(Marker marker) {
    pinnedMarkers.remove(marker);
    notifyListeners();
  }

  void listenToBookingDatabaseValues() async {
    // final firstDriverRef =
    //     await firestoreOperations.retrieveCollectionSnapshots(
    //   'Booking_Details',
    //   documentPath: bookingUserInfo['Zone Number'],
    //   subCollectionPath: '$currentTerminal Queue',
    //   orderBy: 'Queue Position',
    //   sort: true,
    // );
    // if (firstDriverRef.docs.isNotEmpty) {
    //   final driverRef = firstDriverRef.docs.first;
    //   final driverData = driverRef.data() as Map<String, dynamic>;
    //   if (driverData['Body Number'] == bookingUserInfo['Body Number']) {
    //listen
    firestoreOperations.listenToDatabaseValues(
      'Booking_Details',
      listenToCollection: true,
      listener: (snapshot) {
        values.clear();
        documentID.clear();
        userReferenceID.clear();
        userValues.clear();

        for (var element in snapshot.docs.where((data) =>
            data.data()['Booking Status'] == "For Booking" &&
            data.data()['Zone'] == bookingUserInfo['Zone Number'] &&
            data.data()['Terminal'] == currentTerminal)) {
          documentID.add(element.id);
          values.add(element.data());
        }

        notifyListeners();
        // if (values.isNotEmpty) {
        //   riderState.callSnackbar('You have new booking/s');
        // }
      },
    );
    //   }
    // }
  }

  void stopListeningToDatabase() {
    firestoreOperations.stopListener();
  }

  void updateDriverInfoForBooking(Map<String, dynamic> bookingValues) {
    driverInfoForBooking = bookingValues;
    print(bookingValues);
    notifyListeners();
  }

  Future<bool> updateBookingValues(
    String id,
    Map<String, dynamic> values, {
    bool updateOngoingBookingStatus = false,
  }) async {
    bool isAccepted = false;

    await firestoreOperations.startTransaction((transaction) async {
      final bookingRef = firestoreOperations.getDocumentReference(
        'Booking_Details',
        id,
      );
      print(id);

      final snapshot = await transaction.get(bookingRef);

      if (snapshot['Booking Status'] == "For Booking") {
        transaction.set(bookingRef, values, SetOptions(merge: true));
        isAccepted = true;
      }
      if (updateOngoingBookingStatus &&
          snapshot['Booking Status'] == 'Ongoing') {
        transaction.set(bookingRef, values, SetOptions(merge: true));
      }
    });

    notifyListeners();
    return isAccepted;
  }

  LatLng getPickupLatLng(int index) {
    var pickup = values[index]['Pickup LatLng'];
    return LatLng(pickup.latitude, pickup.longitude);
  }

  LatLng getDropOffLatLng(int index) {
    var dropoff = values[index]['Dropoff LatLng'];
    return LatLng(dropoff.latitude, dropoff.longitude);
  }

  String riderPickupAddress(int index) {
    return values[index]['Pickup Location'];
  }

  String riderDropoffAddress(int index) {
    return values[index]['Dropoff Location'];
  }

  String getDateStamp(int index) {
    var timestamp = values[index]['Time Stamp'];
    var timestampToDate = DateFormat.yMMMMd('en_US').format(timestamp.toDate());
    return '$timestampToDate';
  }

  String getTimeStamp(int index) {
    var timestamp = values[index]['Time Stamp'];
    var timeStamptoTime = DateFormat.jm().format(timestamp.toDate());
    return '$timeStamptoTime';
  }

  void updateBookingUserInfo(Map<String, dynamic> user) {
    bookingUserInfo = user;
    notifyListeners();
  }

  void enQueuePosition() {
    //
  }

  void deQueuePosition() {
    //
  }
}

class SuggestionsProvider extends ChangeNotifier {
  Map<String, dynamic> suggestedPlacesDetails = {};
  Map<String, dynamic> suggestedPlacesCache = {};
  String keyword = '';
  Map<String, bool> placesState = {};
  bool isSaved = false;
  final sql = SqliteOperations();

  void updatePlaceDetails(Map<String, dynamic> values) {
    suggestedPlacesDetails = values;
    notifyListeners();
  }

  void clearPlaceDetails() {
    suggestedPlacesDetails.clear();
  }

  void addToCache(Map<String, dynamic> value) {
    if (value.isNotEmpty) {
      value.forEach((key, value) {
        final placeCacheSql = PlaceCacheSql(
          pickupLocation: key,
          pickupLatLng: value,
        );
        final place = placeCacheSql.mapSavedPlace();
        print('Adding to cache: $place');
        sql.insertIntoTable('cachedPlacesResult', place);
      });
    }
    suggestedPlacesCache = value;
    notifyListeners();
  }

  Future<bool> placeExists(String value) async {
    final places = await sql.retrieveValuesInTable('savedPlaces',
        condition: 'Location LIKE ?', args: ['%$value%']);

    placesState[value] = places.isNotEmpty;

    notifyListeners();
    return places.isNotEmpty;
  }

  Future<void> savePlaceInCache(String value, LatLng coordinates) async {
    bool placeExisting = await placeExists(value);

    if (!placeExisting) {
      final placeCacheSql = PlaceCacheSql(
        pickupLocation: value,
        pickupLatLng: coordinates,
      );
      final place = placeCacheSql.mapSavedPlace();

      sql.insertIntoTable('savedPlaces', place);
      placesState[value] = true;
    }
    notifyListeners();
  }

  bool savePlaceState(String place) {
    return placesState[place] ?? false;
  }

  void removePlaceInCache(String value) {
    sql.deleteValueInTable('savedPlaces', 'Location = ?', args: [value]);
    placesState.remove(value);

    notifyListeners();
  }

  Future<Map<String, Object?>> getCachedPlaces(
      String placeID, SuggestionsProvider provider) async {
    Map<String, Object?> places = {};
    print(placeID);
    final dbPlaces = await sql.retrieveValuesInTable('cachedPlacesResult',
        condition: 'Location LIKE ?', args: ['%$placeID%']);
    for (var entry in dbPlaces) {
      places.addAll({
        '${entry['Location']}': LatLng(
            entry['Location_Lat'] as double, entry['Location_Lng'] as double)
      });
    }
    print(dbPlaces);
    print('Final places map: $places');
    return places;
  }
}
