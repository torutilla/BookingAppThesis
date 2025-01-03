import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_try_thesis/models/api_json_management/autocomplete_prediction.dart';
import 'package:flutter_try_thesis/models/api_json_management/directions_json.dart';
import 'package:flutter_try_thesis/models/api_json_management/place.dart';
import 'package:flutter_try_thesis/models/api_json_management/place_auto_complete_response.dart';
import 'package:flutter_try_thesis/models/http_request_files/httpUtility.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class DirectionsClass {
  final BookingProvider bookingProvider;
  String getApiKey = dotenv.env['API_KEY'] ?? '';
  DirectionsClass(this.bookingProvider);

  List<LatLng> bookingPolyline = [];
  Future<void> getDirectionofLocation(LatLng origin, LatLng destination) async {
    // String apiKey = await getApiKey();
    String apiKey = getApiKey;
    Uri directionsApi = Uri.https(
      "maps.googleapis.com",
      "maps/api/directions/json",
      {
        "origin": '${origin.latitude},${origin.longitude}',
        "destination": '${destination.latitude},${destination.longitude}',
        "key": apiKey,
      },
    );

    var response = await HttpUtility.networkUtilityFetchUrl(directionsApi);
    handleResponse(response);
  }

  void decodePolyline(String polylineCode) {
    final polylinePoints = PolylinePoints().decodePolyline(polylineCode);
    final addPolyline =
        polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList();
    for (int i = 0; i < polylinePoints.length; i++) {
      bookingPolyline = addPolyline;
      bookingProvider.addToPolylineList(addPolyline[i]);
    }
  }

  void handleResponse(var response) {
    if (response != null) {
      final directionsResponse =
          PolylineResponse.fromJson(jsonDecode(response));

      final polylinePoints = PolylinePoints().decodePolyline(
          directionsResponse.routes![0].overviewPolyline!.points!);
      bookingProvider.polylineCode =
          directionsResponse.routes![0].overviewPolyline!.points!;
      final addPolyline =
          polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList();
      for (int i = 0; i < polylinePoints.length; i++) {
        bookingPolyline = addPolyline;
        bookingProvider.addToPolylineList(addPolyline[i]);
      }
    }
  }
}

class PlaceSuggestions {
  final SuggestionsProvider suggestionsProvider;
  PlaceSuggestions(this.suggestionsProvider);
  Future<List<AutocompletePrediction>?> generateSuggestions(
      String input, Position userLocation) async {
    // String apiKey = await getApiKey();
    String getApiKey = dotenv.env['API_KEY'] ?? '';

    String apiKey = getApiKey;

    Uri placesAutoComplete = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": input,
        "key": apiKey,
        "location": '${userLocation.latitude},${userLocation.longitude}',
        "radius": '50',
        "components": 'country:ph'
      },
    );

    String? response =
        await HttpUtility.networkUtilityFetchUrl(placesAutoComplete);

    if (response != null) {
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.parseAutocompleteResult(response);

      if (result.predictions != null) {
        return result.predictions!;
      }
    }
    return null;
  }
}

class PlaceSearch {
  String getApiKey = dotenv.env['API_KEY'] ?? '';
  Map<String, dynamic> addressWithLatLng = {};
  Future<Map<String, dynamic>> generatePlaces(
      String input, Position userLocation) async {
    Uri placeTextSearch = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/textsearch/json",
      {
        "fields": 'formatted_address,name,geometry',
        "query": input,
        "radius": '50',
        "location": '${userLocation.latitude},${userLocation.longitude}',
        "key": getApiKey,
      },
    );
    String? response =
        await HttpUtility.networkUtilityFetchUrl(placeTextSearch);
    if (response != null) {
      PlaceTextSearch textSearchResponse =
          PlaceTextSearch.parsePlaceTextSearch(response);

      if (textSearchResponse.results != null) {
        for (int i = 0; i < textSearchResponse.results!.length; i++) {
          addressWithLatLng[textSearchResponse.results![i].name!] =
              textSearchResponse.results![i].locationGeometry!.latLng;
        }
      }
    }
    return addressWithLatLng;
  }
}
