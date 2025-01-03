import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_try_thesis/commuter/commuter_drawer/savedPlaces.dart';
import 'package:flutter_try_thesis/constants/globalFunctions.dart';
import 'package:flutter_try_thesis/constants/removeOverlay.dart';
import 'package:flutter_try_thesis/constants/tariffs.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/numberInputField.dart';
import 'package:flutter_try_thesis/constants/zones.dart';
import 'package:flutter_try_thesis/models/placemark/getPlacemark.dart';
import 'package:flutter_try_thesis/models/cache_manager/sharedPreferences/userSharedPreferences.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/bookingHistoryCacheModel.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/sqliteOperations.dart';
import 'package:flutter_try_thesis/constants/tagaytayCoordinates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/models/api_json_management/googleMapApis.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/alert.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/textButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:flutter_try_thesis/routing/router.dart';
import 'package:flutter_try_thesis/map/mainMap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// import 'package:geolocator/geolocator.dart';

class BookingDetails extends StatefulWidget {
  final bool pickUp;

  const BookingDetails({
    super.key,
    this.pickUp = false,
  });

  @override
  BookingDetailsState createState() => BookingDetailsState();
  static String getAddressDisplayOnOverlay = '';
}

class BookingDetailsState extends State<BookingDetails> {
  late DirectionsClass direction;
  final FocusNode pickupFocusNode = FocusNode();
  final FocusNode dropoffFocusNode = FocusNode();
  final FocusNode dummyFocus = FocusNode();
  final FocusNode commentNode = FocusNode();
  String _pickUpAddress = '';
  String _dropOffAddress = '';
  LatLng? _pickUpLatLng;
  LatLng? _dropOffLatLng;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _passengerCount = '1';
  bool isLoading = false;
  Color pickupColor = Colors.transparent;
  Color dropoffColor = Colors.transparent;
  bool _enablePickUpFieldCloseButton = false;
  bool _enableDropOffFieldCloseButton = false;
  UserSharedPreferences sharedPreferences = UserSharedPreferences();
  final sql = SqliteOperations();
  Timer? _debounce;
  OverlayEntry? overlayEntryMap;
  OverlayEntry? overlayEntrySuggestions;
  final GlobalKey _pickUpKey = GlobalKey();
  final GlobalKey _dropOffKey = GlobalKey();
  GlobalKey<MainMapState> mapStateKey = GlobalKey<MainMapState>();
  Offset _pickUpTextFieldPos = Offset.zero;
  Offset _dropOffTextFieldPos = Offset.zero;
  SuggestionsProvider suggestions = SuggestionsProvider();
  late Position userLocation;
  // Set<Marker> _mapMarker = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    BookingProvider bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    _pickupController.text = bookingProvider.pickupLocation;
    _dropoffController.text = bookingProvider.dropoffLocation;

    _pickupController.addListener(() {
      if (_pickupController.text.isNotEmpty) {
        _enablePickUpFieldCloseButton = true;
        closeCircularIndicator();
      } else {
        if (overlayEntrySuggestions != null) {
          removeOverlay(overlayEntrySuggestions);
        }
      }
    });
    _dropoffController.addListener(() {
      if (_dropoffController.text.isNotEmpty) {
        _enableDropOffFieldCloseButton = true;
        closeCircularIndicator();
      } else {
        if (overlayEntrySuggestions != null) {
          removeOverlay(overlayEntrySuggestions);
        }
      }
    });

    if (_pickupController.text.isNotEmpty &&
        _dropoffController.text.isNotEmpty) {
      _enableDropOffFieldCloseButton = true;
      _enablePickUpFieldCloseButton = true;
    }
    if (widget.pickUp) {
      pickupFocusNode.requestFocus();
    } else {
      dropoffFocusNode.requestFocus();
    }

    pickupFocusNode.addListener(() {
      setState(() {
        pickupColor =
            pickupFocusNode.hasFocus ? grayInputBox : Colors.transparent;
      });
    });
    dropoffFocusNode.addListener(() {
      setState(() {
        dropoffColor =
            dropoffFocusNode.hasFocus ? grayInputBox : Colors.transparent;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox pickupRenderBox =
          _pickUpKey.currentContext!.findRenderObject() as RenderBox;
      final pickUpPosition = pickupRenderBox.localToGlobal(Offset.zero);

      final RenderBox dropoffRenderBox =
          _dropOffKey.currentContext!.findRenderObject() as RenderBox;
      final dropOffPosition = dropoffRenderBox.localToGlobal(Offset.zero);
      setState(() {
        _pickUpTextFieldPos = pickUpPosition;
        _dropOffTextFieldPos = dropOffPosition;
      });
    });
  }

  @override
  void dispose() {
    pickupFocusNode.dispose();
    dropoffFocusNode.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          if (overlayEntryMap != null) {
            removeOverlay(overlayEntryMap);
          }
          if (overlayEntrySuggestions != null) {
            removeOverlay(overlayEntrySuggestions);
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: softWhite,
          appBar: AppBar(
            backgroundColor: primaryColor,
            leading: IconButton(
              onPressed: () {
                _pickUpAddress = _pickupController.text;
                _dropOffAddress = _dropoffController.text;
                pickupFocusNode.unfocus();
                dropoffFocusNode.unfocus();
                MyRouter.navigateToPrevious(context);
                if (overlayEntrySuggestions != null) {
                  removeOverlay(overlayEntrySuggestions);
                }
                if (overlayEntryMap != null) {
                  removeOverlay(overlayEntryMap);
                }
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            title: Text(
              'Set Locations',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.white,
                  ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Builder(builder: (context) {
              return Stack(
                children: [
                  bookingWidgets(),
                  if (isLoading)
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        ModalBarrier(
                          color: Colors.black12,
                        ),
                        CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ],
                    )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget bookingWidgets() {
    return Column(
      children: [
        SizedBox(
          width: ScreenUtil.parentWidth(context),
          height: ScreenUtil.parentHeight(context) * 0.18,
          child: LayoutBuilder(builder: (context, constraints) {
            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Consumer<BookingProvider>(
                  builder: (context, bookingProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0, left: 16),
                          child: Icon(
                            Icons.my_location,
                            size: 24,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth * 0.75,
                          height: 40,
                          child: Consumer<SuggestionsProvider>(
                              builder: (context, provider, child) {
                            return TextFormField(
                              key: _pickUpKey,
                              textInputAction: TextInputAction.search,
                              controller: _pickupController,
                              cursorColor: primaryColor,
                              focusNode: pickupFocusNode,
                              onChanged: (value) {
                                _generateSuggestions(value, provider);
                              },
                              style: const TextStyle(
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                suffixIcon: _enablePickUpFieldCloseButton
                                    ? IconButton(
                                        onPressed: () {
                                          _pickupController.text = '';
                                          bookingProvider.resetBookingInfo(
                                              resetPickup: true);
                                          _enablePickUpFieldCloseButton = false;
                                          suggestions.clearPlaceDetails();
                                          removeOverlay(
                                              overlayEntrySuggestions);
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 14,
                                        ))
                                    : null,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                fillColor: pickupColor,
                                filled: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide.none),
                                hintText: 'Search Pick-up Location',
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const Divider(
                      indent: 16,
                      endIndent: 16,
                      height: 2,
                      thickness: 1,
                      color: grayInputBox,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0, left: 16),
                          child: Icon(
                            Icons.location_on,
                            size: 24,
                            color: accentColor,
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth * 0.75,
                          height: 40,
                          child: Consumer<SuggestionsProvider>(
                              builder: (context, provider, child) {
                            return TextFormField(
                              onTap: () {
                                pickupFocusNode.requestFocus();
                              },
                              key: _dropOffKey,
                              controller: _dropoffController,
                              cursorColor: accentColor,
                              onChanged: (value) {
                                _generateSuggestions(value, provider);
                              },
                              focusNode: dropoffFocusNode,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis),
                              decoration: InputDecoration(
                                suffixIcon: _enableDropOffFieldCloseButton
                                    ? IconButton(
                                        onPressed: () {
                                          _dropoffController.text = '';
                                          bookingProvider.resetBookingInfo(
                                              resetDropoff: true);
                                          _enableDropOffFieldCloseButton =
                                              false;
                                          removeOverlay(
                                              overlayEntrySuggestions);
                                          suggestions.clearPlaceDetails();
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 14,
                                        ))
                                    : null,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                fillColor: dropoffColor,
                                filled: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide.none),
                                hintText: 'Search Drop-off Location',
                              ),
                            );
                          }),
                        ),
                      ],
                    )
                  ],
                );
              }),
            );
          }),
        ),
        Container(
          color: grayInputBox,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 110,
                child: TextButtonUtility(
                  elevation: 6,
                  borderRadius: 24,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onpressed: () async {
                    try {
                      var result = await sql.retrieveValuesInTable(
                          'bookingHistory',
                          condition: 'id = ?',
                          args: ["Recent"]);

                      _retrieveCache(result);
                    } catch (e) {
                      print('error retrieving values $e');
                    }
                  },
                  text: 'Recent',
                  icon: const Icon(Icons.history),
                ),
              ),
              SizedBox(
                width: 110,
                child: TextButtonUtility(
                  elevation: 6,
                  borderRadius: 24,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onpressed: () {},
                  text: 'Home',
                  icon: const Icon(Icons.home),
                ),
              ),
              SizedBox(
                width: 110,
                child: TextButtonUtility(
                  elevation: 6,
                  borderRadius: 24,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onpressed: () {},
                  text: 'Work',
                  icon: const Icon(Icons.work),
                ),
              ),
            ],
          ),
        ),
        Consumer<BookingProvider>(builder: (context, bookingProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  height: 180,
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(4),
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        onTap: () {
                          setState(() {
                            isLoading = true;
                          });
                          _requestLocationPermission();
                          _setAddressToTextBox(userLocation, bookingProvider);
                        },
                        leading: const Icon(
                          Icons.share_location_outlined,
                          color: primaryColor,
                        ),
                        title: Text(
                          'Use my current location',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w400),
                        ),
                      ),
                      const Divider(
                        indent: 16,
                        endIndent: 16,
                        height: 2,
                        thickness: 0.3,
                        color: grayColor,
                      ),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        onTap: () {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.hide');
                          _goToMapWithOverlay();
                        },
                        leading: const Icon(
                          Icons.map,
                          color: primaryColor,
                        ),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 20,
                          color: accentColor,
                        ),
                        title: Text('Pin location on map',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w400)),
                      ),
                      const Divider(
                        indent: 16,
                        endIndent: 16,
                        height: 2,
                        thickness: 0.3,
                        color: grayColor,
                      ),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        onTap: () {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.hide');
                          if (overlayEntrySuggestions != null) {
                            removeOverlay(overlayEntrySuggestions);
                          }
                          MyRouter.navigateToNext(
                              context,
                              SavedPlaces(
                                assignToBooking: true,
                                onTapCallback: (address, coordinates,
                                    {pickup}) {
                                  if (pickup!) {
                                    _getProvider(context)
                                        .updatePickup(address, coordinates);
                                    _pickupController.text =
                                        _getProvider(context).pickupLocation;
                                  } else {
                                    _getProvider(context)
                                        .updateDropoff(address, coordinates);
                                    _dropoffController.text =
                                        _getProvider(context).dropoffLocation;
                                  }
                                  Navigator.pop(context);
                                  _updateFocus();
                                },
                              ));
                        },
                        leading: const Icon(
                          Icons.bookmark,
                          color: primaryColor,
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                        title: Text('Saved Places',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w400)),
                      ),
                    ],
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Number of passengers'),
                  NumberInputField(
                    width: 130,
                    height: 40,
                    backgroundColor: grayInputBox,
                    borderRadius: 8,
                    callBack: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'The maximum number of passengers allowed is 3.')));
                    },
                    valueCallback: (number) {
                      setState(() {
                        _passengerCount = number;
                      });
                      print(_passengerCount);
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 8),
                    child: Text('Note to Driver:'),
                  ),
                  SizedBox(
                    height: ScreenUtil.parentHeight(context) * 0.20,
                    width: ScreenUtil.parentWidth(context) * 0.80,
                    child: TextFormField(
                      controller: _noteController,
                      focusNode: commentNode,
                      cursorColor: primaryColor,
                      textAlign: TextAlign.left,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write something...',
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PrimaryButton(
                  backgroundColor: _pickupController.text.isNotEmpty &&
                          _dropoffController.text.isNotEmpty
                      ? primaryColor
                      : grayColor,
                  onPressed: () {
                    if (_pickupController.text.isNotEmpty &&
                        _dropoffController.text.isNotEmpty) {
                      showDialog(
                          barrierDismissible: false,
                          barrierColor: Colors.black12,
                          context: context,
                          builder: (context) {
                            return Center(
                                child: CircularProgressIndicator(
                              color: secondaryColor,
                            ));
                          });

                      _updateBookingState();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please set your locations to proceed.'),
                        ),
                      );
                    }
                  },
                  buttonText: 'Confirm',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _goToMapWithOverlay() {
    overlayEntryMap = OverlayEntry(
      builder: (BuildContext context) {
        return Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ModalBarrier(
                onDismiss: () {
                  removeOverlay(overlayEntryMap);
                },
                color: Colors.black45,
              ),
              Material(
                child: SizedBox(
                  width: ScreenUtil.parentWidth(context) * 0.8,
                  height: ScreenUtil.parentHeight(context) * 0.8,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        children: [
                          MainMap(
                            key: mapStateKey,
                            enableOnTapPinning: true,
                          ),
                          Container(
                            width: constraints.maxWidth * 0.9,
                            height: 80,
                            margin: const EdgeInsets.all(8.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  side: BorderSide(
                                    color: pickupFocusNode.hasFocus
                                        ? primaryColor
                                        : accentColor,
                                  )),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextTitle(
                                        text: bookingProvider.pinAddress1,
                                        textColor: pickupFocusNode.hasFocus
                                            ? primaryColor
                                            : accentColor,
                                        textAlign: TextAlign.left,
                                        fontSize: 14,
                                      ),
                                      Text(
                                        bookingProvider.pinAddress2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.bottomCenter,
                            child: PrimaryButton(
                              backgroundColor:
                                  bookingProvider.isBookingButtonAvailable
                                      ? primaryColor
                                      : grayColor,
                              onPressed: bookingProvider
                                      .isBookingButtonAvailable
                                  ? () {
                                      _updateBookingAddress(bookingProvider);

                                      if (overlayEntryMap != null) {
                                        removeOverlay(overlayEntryMap);
                                      }
                                    }
                                  : () {},
                              buttonText: 'Confirm',
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        });
      },
    );

    Overlay.of(context, debugRequiredFor: widget).insert(overlayEntryMap!);
  }

  SuggestionsProvider _getSuggestionsProvider(BuildContext context) {
    return Provider.of<SuggestionsProvider>(context, listen: false);
  }

  Future<void> _placeSuggestionsOverlay(
      Map<String, dynamic> suggestedPlaces) async {
    for (int i = 0; i < suggestedPlaces.length; i++) {
      String placeName = suggestedPlaces.keys.elementAt(i);
      bool exists =
          await _getSuggestionsProvider(context).placeExists(placeName);
      _getSuggestionsProvider(context).placesState[placeName] = exists;
    }
    overlayEntrySuggestions = OverlayEntry(builder: (context) {
      double topPosition = pickupFocusNode.hasFocus
          ? _pickUpTextFieldPos.dy + 42
          : _dropOffTextFieldPos.dy + 42;
      double leftPosition = pickupFocusNode.hasFocus
          ? _pickUpTextFieldPos.dx
          : _dropOffTextFieldPos.dx;
      return Positioned(
        top: topPosition,
        left: leftPosition,
        right: 20,
        child: Material(
          elevation: 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 160,
              maxWidth: 50,
            ),
            child: Consumer<SuggestionsProvider>(
                builder: (context, suggestions, child) {
              return ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                shrinkWrap: true,
                itemCount: suggestedPlaces.length,
                itemBuilder: (context, index) {
                  String placeName = suggestedPlaces.keys.elementAt(index);
                  bool isSaved = suggestions.savePlaceState(placeName);
                  return Consumer<BookingProvider>(
                      builder: (context, provider, child) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                      ),
                      trailing: IconButton(
                          onPressed: () async {
                            if (isSaved) {
                              suggestions.removePlaceInCache(placeName);
                            } else {
                              suggestions.savePlaceInCache(
                                  placeName, suggestedPlaces[placeName]);
                            }
                          },
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border_outlined,
                            color: accentColor,
                          )),
                      title: Text(placeName),
                      onTap: () {
                        provider.pinAddress1 = placeName;
                        provider.pinLatLng = suggestedPlaces[placeName];
                        _updateBookingAddress(provider);

                        removeOverlay(overlayEntrySuggestions);
                      },
                    );
                  });
                },
              );
            }),
          ),
        ),
      );
    });

    Overlay.of(context, debugRequiredFor: widget)
        .insert(overlayEntrySuggestions!);
  }

  void closeCircularIndicator() {
    setState(() => isLoading = false);
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
              iconAndButtonColor: warningColor,
              title: 'Permission Denied',
              content:
                  'Cannot access current location. Please grant the permission to location services.',
              onclick: () {
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> _requestLocationPermission() async {
    userLocation = (await getCurrentLocation())!;
  }

  void _setAddressToTextBox(
      Position userLocation, BookingProvider provider) async {
    String address = await generateAddressFromPlacemark(
        LatLng(userLocation.latitude, userLocation.longitude));
    if (dropoffFocusNode.hasFocus) {
      _dropoffController.text = address;
      _enableDropOffFieldCloseButton = _dropoffController.text.isNotEmpty;
      provider.updateDropoff(_dropoffController.text,
          LatLng(userLocation.latitude, userLocation.longitude));
    } else if (pickupFocusNode.hasFocus) {
      _pickupController.text = address;
      _enablePickUpFieldCloseButton = _pickupController.text.isNotEmpty;
      provider.updatePickup(_pickupController.text,
          LatLng(userLocation.latitude, userLocation.longitude));
    } else {
      _pickupController.text = address;
      _enablePickUpFieldCloseButton = _pickupController.text.isNotEmpty;
      provider.updatePickup(_pickupController.text,
          LatLng(userLocation.latitude, userLocation.longitude));
    }
    _updateFocus();
  }

  void _updateBookingAddress(BookingProvider bookingProvider) {
    if (pickupFocusNode.hasFocus) {
      _pickupController.text =
          '${bookingProvider.pinAddress1}, ${bookingProvider.pinAddress2}';
      _enablePickUpFieldCloseButton = _pickupController.text.isNotEmpty;
      bookingProvider.updatePickup(
          _pickupController.text, bookingProvider.pinLatLng!);
    } else if (dropoffFocusNode.hasFocus) {
      _dropoffController.text =
          '${bookingProvider.pinAddress1}, ${bookingProvider.pinAddress2}';
      _enableDropOffFieldCloseButton = _dropoffController.text.isNotEmpty;
      bookingProvider.updateDropoff(
          _dropoffController.text, bookingProvider.pinLatLng!);
    }
    _updateFocus();
  }

  void _updateBookingState() async {
    BookingProvider bookingClass =
        Provider.of<BookingProvider>(context, listen: false);
    bookingClass.bookingPolyline = [];
    DirectionsClass direction = DirectionsClass(bookingClass);
    String id =
        '${bookingClass.pickupLocation} ${bookingClass.dropoffLocation}';
    try {
      if (!bookingClass.pinnedMarkers.contains(const MarkerId('Pickup Pin'))) {
        bookingClass.addToPinnedMarkers(bookingClass.generateMarker(
            'Pickup Pin', bookingClass.pickupLatLng!));
      }
      if (!bookingClass.pinnedMarkers.contains(const MarkerId('Dropoff Pin'))) {
        bookingClass.addToPinnedMarkers(bookingClass.generateMarker(
            'Dropoff Pin', bookingClass.dropoffLatLng!));
      }
      if (bookingClass.bookingPolyline.isEmpty) {
        if (bookingClass.BookingPolylineList.containsKey(id)) {
          List<LatLng> cachedPolyline =
              List<LatLng>.from(bookingClass.BookingPolylineList[id]!);
          bookingClass.addPolylineListToPolyline(cachedPolyline);
        } else {
          await direction.getDirectionofLocation(bookingClass.pickupLatLng!,
              bookingClass.dropoffLatLng!); //call Directions API then assign
          bookingClass.BookingPolylineList.putIfAbsent(
              '${bookingClass.pickupLocation} ${bookingClass.dropoffLocation}',
              () => direction.bookingPolyline);
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      print('error adding polyline $e');
    }
    _calculatePrice(bookingClass);

    if (bookingClass.bookingPolyline.isNotEmpty) {
      MyRouter.navigateToPrevious(context);
      bookingClass.passengerCount = _passengerCount;
      bookingClass.notes = _noteController.text;
      pickupFocusNode.unfocus();
      dropoffFocusNode.unfocus();
      if (overlayEntrySuggestions != null) {
        removeOverlay(overlayEntrySuggestions);
      }
    } else {
      print('Coordinates are empty');
    }
    _addBookingToCache();
  }

  void _generateSuggestions(String value, SuggestionsProvider provider) async {
    removeOverlay(overlayEntrySuggestions);

    PlaceSearch placeSearch = PlaceSearch();
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(seconds: 1), () async {
      if (value.isNotEmpty) {
        var cachePlaces = await provider.getCachedPlaces(value, provider);
        if (cachePlaces.isNotEmpty) {
          _placeSuggestionsOverlay(cachePlaces);
        } else {
          var returnValue =
              await placeSearch.generatePlaces(value, userLocation);
          Map<String, dynamic> generatedPlaces = {};
          returnValue.forEach(
            (key, value) {
              for (var barangay in barangayCoordinates.entries) {
                if (isPointInPolygon(
                    value, barangayCoordinates[barangay.key]!)) {
                  generatedPlaces[key] = value;
                  break;
                }
              }
            },
          );
          provider.updatePlaceDetails(generatedPlaces);
          provider.addToCache(generatedPlaces);
          _placeSuggestionsOverlay(provider.suggestedPlacesDetails);
        }
      }
    });
  }

  void _updateFocus() {
    if (_dropoffController.text.isNotEmpty &&
        _pickupController.text.isNotEmpty) {
      commentNode.requestFocus();
    } else if (_pickupController.text.isNotEmpty) {
      dropoffFocusNode.requestFocus();
    } else {
      pickupFocusNode.requestFocus();
    }
  }

  void _addBookingToCache() {
    var bookingProvider = _getProvider(context);
    PlaceCacheSql sqlPlaceCache = PlaceCacheSql(
      bookingID: 'Recent',
      pickupLocation: bookingProvider.pickupLocation,
      dropoffLocation: bookingProvider.dropoffLocation,
      pickupLatLng: bookingProvider.pickupLatLng!,
      dropoffLatLng: bookingProvider.dropoffLatLng!,
      polyline: bookingProvider.polylineCode,
    );
    var result = sqlPlaceCache.mapBooking();
    try {
      sql.insertIntoTable('bookingHistory', result);
    } catch (e) {
      print('error inserting to table $e');
    }
    print(result);
  }

  void _retrieveCache(List<Map<String, Object?>> result) async {
    var recentBooking = result[0];
    _pickupController.text = recentBooking['Pickup_Location'] as String;
    _dropoffController.text = recentBooking['Dropoff_Location'] as String;
    _getProvider(context).updatePickup(
      recentBooking['Pickup_Location'] as String,
      LatLng(recentBooking['Pickup_Lat'] as double,
          recentBooking['Pickup_Lng'] as double),
    );
    _getProvider(context).updateDropoff(
      recentBooking['Dropoff_Location'] as String,
      LatLng(recentBooking['Dropoff_Lat'] as double,
          recentBooking['Dropoff_Lng'] as double),
    );
    String polylinePoints = result[0]['Polyline'] as String;
    List<LatLng> polyline = PolylinePoints()
        .decodePolyline(polylinePoints)
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();
    _getProvider(context).addPolylineListToPolyline(polyline);

    _updateFocus();
  }

  BookingProvider _getProvider(BuildContext context) {
    return Provider.of<BookingProvider>(context, listen: false);
  }

  double getPriceBasedOnDistance(LatLng pickup, LatLng dropoff) {
    final distanceInMeters = haversineFormula(pickup, dropoff);
    final price = (distanceInMeters / 100) * 2;

    return price;
  }

  void _calculatePrice(BookingProvider provider) {
    //determine terminal first
    provider.updateZone(getZoneofPlace(provider.pickupLatLng!));
    // final closest = findClosestTerminal(
    //     provider.pickupLatLng!,
    //     terminals
    //         .where((terminal) => terminal.zone == provider.zoneRef)
    //         .toList());
    final closestTerminalCoordinate = findClosestLatLng(
        provider.pickupLatLng!,
        terminals
            .where((e) => e.zone == provider.zoneRef)
            .map((terminal) => terminal.coordinates)
            .toList());
    final terminal = terminals
        .where((e) => e.coordinates == closestTerminalCoordinate)
        .toList();
    print('Closest Terminal: ${terminal[0].zone}, ${terminal[0].terminalName}');
    provider.updateTerminal(terminal[0].terminalName);
    final filteredTariffsBasedOnTerminal = tariffsList
        .expand((innerList) => innerList.where((tariff) =>
            tariff.zone == provider.zoneRef &&
            tariff.terminalName == terminal[0].terminalName))
        .toList();
    print(filteredTariffsBasedOnTerminal
        .map((terminal) => terminal.locationLatLng)
        .toList());
    final closestTariffLocationInCoordinate = findClosestLatLng(
        provider.dropoffLatLng!,
        filteredTariffsBasedOnTerminal
            .map((terminal) => terminal.locationLatLng)
            .toList());
    final closestLocationInTariff = filteredTariffsBasedOnTerminal
        .where((e) => e.locationLatLng == closestTariffLocationInCoordinate)
        .toList();
    print(closestLocationInTariff[0].placeName);
    if (isLocationWithinBounds(provider.dropoffLatLng!,
        closestLocationInTariff[0].locationLatLng, 50)) {
      provider.updatePrice(closestLocationInTariff[0].price);
    } else {
      int baseFare = closestLocationInTariff[0].price;
      print('Base Fare: $baseFare');
      final distancePrice = getPriceBasedOnDistance(
          provider.dropoffLatLng!, closestLocationInTariff[0].locationLatLng);
      baseFare += distancePrice.toInt();
      provider.updatePrice(baseFare);
      print('Final Price: ${provider.price}');
    }

    //get
    // convertFareListToTariff()
    // provider.updatePrice(1);
  }
}
