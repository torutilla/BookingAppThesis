import 'dart:async';

import 'package:action_slider/action_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_try_thesis/constants/logoMain.dart';
import 'package:flutter_try_thesis/constants/removeOverlay.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/actionSlider.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/globalFunctions.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/alert.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/bookingDetailsContent.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/linearProgress.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/overlayEntryCard.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilDrawer.dart';
import 'package:flutter_try_thesis/map/mainMap.dart';
import 'package:flutter_try_thesis/driver/rider_main_screen/ongoingBookings.dart';
import 'package:flutter_try_thesis/driver/rider_main_screen/riderBookingHistory.dart';
import 'package:flutter_try_thesis/models/api_json_management/googleMapApis.dart';
import 'package:flutter_try_thesis/models/firestore_operations/firestoreOperations.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:flutter_try_thesis/models/providers/historyProvider.dart';
import 'package:flutter_try_thesis/models/cache_manager/sharedPreferences/userSharedPreferences.dart';
import 'package:flutter_try_thesis/constants/zones.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/navigatorKey.dart';

class RiderScreenMap extends StatefulWidget {
  const RiderScreenMap({
    super.key,
  });

  @override
  RiderMapState createState() => RiderMapState();
}

class RiderMapState extends State<RiderScreenMap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Color cardColor = const Color.fromARGB(255, 243, 243, 243);
  FirestoreOperations firestoreOperations = FirestoreOperations();
  MainMapState mapState = MainMapState();
  StreamSubscription<Position>? currentLocationSubscription;
  UserSharedPreferences sharedPreferences = UserSharedPreferences();

  int currentIndex = 1;
  late TabController mainTabController;
  DraggableScrollableController draggableController =
      DraggableScrollableController();
  PersistentBottomSheetController? bottomSheet;
  OverlayEntry? detailsOverlay;
  GlobalKey<MainMapState> mainMapKey = GlobalKey<MainMapState>();
  bool isOnline = false;
  bool isBookingOngoing = false;
  double sliderValue = 0;
  late Position userLocation;
  late final List<Widget> _currentPage;
  String currentPickupLocation = '';
  String currentDropoffLocation = '';
  String currentNote = '';
  String currentDocId = '';
  String currentDate = '';
  String currentTime = '';
  String bookingStatus = '';
  String currentPassenger = '';
  String currentNumber = '';

  int mainBookingIndex = 0;

  DraggableScrollableController bookingDraggableController =
      DraggableScrollableController();
  DraggableScrollableController queueDraggable =
      DraggableScrollableController();
  Timer? queueTimer;
  final List<IconData> _bottomNavsIcon = [
    Icons.history,
    Icons.home,
    Icons.hourglass_top_rounded,
  ];

  final List<String> _bottomNavsIconLabel = [
    'History',
    'Home',
    'Ongoing',
  ];

  double trackWidth = 250;
  late AnimationController animationController;

  bool completeButton = false;

  bool startQueueListener = false;
  bool enableQueueDraggable = false;
  bool isTimerActive = true;

  String currentPolyline = '';

  bool _hasShownCancelledDialog = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (currentDocId.isNotEmpty) {
        sharedPreferences.addToCache({"Booking ID": currentDocId});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentPos();
    sharedPreferences.addToCache({"Initial Screen": "Rider"});
    _loadSharedPreferences();
    mainTabController = TabController(length: 3, vsync: this, initialIndex: 1);
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _currentPage = [
      const RiderBookingHistory(),
      MainMap(
        key: mainMapKey,
      ),
      const OngoingBookings(),
    ];
    mainTabController.addListener(() {
      if (mainTabController.index != 1) {
        controlDraggable(draggableController, 0, Curves.easeOutCubic);
        controlDraggable(bookingDraggableController, 0, Curves.easeOutCubic);
      }
    });

    reloadTerminatedBooking();
  }

  void callSnackbar(String content) {
    ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
        .showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 500),
            content: Text(content)));
  }

  void controlDraggable(
      DraggableScrollableController controller, double size, Curve curve) {
    controller.animateTo(size,
        duration: const Duration(milliseconds: 400), curve: curve);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(builder: (_, provider, child) {
      return Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: primaryColor,
            height: 70,
            notchMargin: 8,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(0),
            child: TabBar(
                isScrollable: false,
                indicator: BoxDecoration(
                  color: accentColor.withBlue(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                controller: mainTabController,
                labelColor: softWhite,
                unselectedLabelColor: secondaryColor.withOpacity(0.4),
                tabs: List.generate(3, (index) {
                  return Tab(
                    text: _bottomNavsIconLabel[index],
                    icon: Icon(_bottomNavsIcon[index]),
                  );
                })),
          ),
          drawer: UtilDriverDrawer(
            onLogout: () {
              sharedPreferences.addToCache({"Initial Screen": "Login"});
            },
            driverName: provider.bookingUserInfo['Full Name'] ?? 'Driver',
            driverContact:
                provider.bookingUserInfo['Contact Number'] ?? '+630000000000',
          ),
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSwitch(
                    activeColor: accentColor,
                    trackColor: secondaryColor.withOpacity(0.2),
                    value: isOnline,
                    onChanged: (value) {
                      if (isBookingOngoing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'The switch cannot be toggled while a booking is in progress.')),
                        );
                        return;
                      }
                      if (locationIsInTerminal()) {
                        _getTerminal();
                        setState(() {
                          isOnline = value;
                          enableQueueDraggable = true;
                          if (isOnline) {
                            controlDraggable(
                                queueDraggable, 0.9, Curves.easeInCubic);
                            //     provider.updateTerminal(_getTerminal());
                            //     Future.delayed(const Duration(seconds: 1), () {
                            // provider.listenToBookingDatabaseValues();
                            //     });
                            // controlDraggable(
                            //     draggableController, 1, Curves.easeInCubic);
                          } else {
                            dequeuePosition();
                            controlDraggable(
                                draggableController, 0, Curves.easeOutCubic);
                            controlDraggable(
                                queueDraggable, 0, Curves.easeOutCubic);
                            //     isBookingOngoing = false;
                            //     provider.stopListeningToDatabase();
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Not currently in terminal')),
                        );
                      }
                    }),
              ),
            ],
            backgroundColor: primaryColor,
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {});

                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            title: Text(
              'Welcome, ${_getFirstNameInFirstSpace(provider.bookingUserInfo['Full Name'] ?? 'Driver')}!',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Colors.white, fontSize: 17),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: mainTabController,
                  children: List.generate(3, (index) {
                    return _currentPage[index];
                  })),
              Container(
                margin: const EdgeInsets.only(bottom: 40, right: 16),
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  tooltip: 'Show bookings',
                  mini: true,
                  backgroundColor: isOnline ? primaryColor : grayColor,
                  shape: const CircleBorder(),
                  onPressed: () {
                    if (enableQueueDraggable) {
                      controlDraggable(queueDraggable, 0.9, Curves.easeInCubic);
                    } else if (isOnline && isBookingOngoing) {
                      controlDraggable(
                          bookingDraggableController, 0.9, Curves.easeInCubic);
                    } else if (isOnline) {
                      controlDraggable(
                          draggableController, 0.9, Curves.easeInCubic);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_drop_up_sharp,
                    color: softWhite,
                  ),
                ),
              ),
              if (!isOnline)
                const Stack(
                  alignment: Alignment.center,
                  children: [
                    ModalBarrier(
                      color: Colors.black38,
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextTitle(
                            text: 'Bookings are currently disabled.',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          TextTitle(
                            text:
                                'Toggle the switch in the top-right corner to enable booking.',
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              showBookingDraggableSheet(context),
              _initializeSheet(context),
              queueDraggableSheet(context),
            ],
          ));
    });
  }

  Widget queueDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
        controller: queueDraggable,
        initialChildSize: 0,
        minChildSize: 0,
        maxChildSize: 0.8,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              controller: controller,
              child: SizedBox(
                height: ScreenUtil.parentHeight(context) * 0.6,
                child: Consumer<BookingProvider>(
                    builder: (context, provider, child) {
                  return LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 80,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: grayColor,
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              // SvgPicture.asset(
                              //   'assets/images/Bukyo.svg',
                              //   height: 80,
                              //   colorFilter: const ColorFilter.mode(
                              //       primaryColor, BlendMode.srcIn),
                              // ),
                              Column(
                                children: [
                                  const TextTitle(
                                    text: 'Join Queue',
                                    textColor: blackColor,
                                  ),
                                  Text(
                                      '${provider.bookingUserInfo['Zone Number']}: ${provider.currentTerminal}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder(
                            stream: queueListener(),
                            builder: (_, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: constraints.maxHeight * 0.4,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      Text('Calculating your position...'),
                                    ],
                                  ),
                                );
                              }
                              if (startQueueListener) {
                                if (snapshot.data == 0) {
                                  queueTimer =
                                      Timer(const Duration(seconds: 5), () {
                                    if (isTimerActive) {
                                      controlDraggable(queueDraggable, 0,
                                          Curves.easeOutCubic);
                                      Future.delayed(
                                          const Duration(seconds: 1));
                                      controlDraggable(draggableController, 1,
                                          Curves.easeInCubic);
                                      provider.listenToBookingDatabaseValues();
                                      setState(() {
                                        startQueueListener = false;
                                        enableQueueDraggable = false;
                                      });
                                    }
                                  });
                                  return SizedBox(
                                    height: constraints.maxHeight * 0.4,
                                    child: const Center(
                                      child: Text(
                                          'You are next in line. Please wait...'),
                                    ),
                                  );
                                }
                                if (snapshot.data != null) {
                                  return SizedBox(
                                    height: constraints.maxHeight * 0.4,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Your position in queue:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        TextTitle(
                                          text: '${snapshot.data!}',
                                          textColor: blackColor,
                                          fontSize: 120,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                              return SizedBox(
                                height: constraints.maxHeight * 0.4,
                                child: Column(
                                  children: [
                                    Text(
                                      'Drivers in Queue:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: accentColor,
                                              fontWeight: FontWeight.w700),
                                    ),
                                    TextTitle(
                                      text: '${snapshot.data /*?? 0*/}',
                                      textColor: blackColor,
                                      fontSize: 120,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PrimaryButton(
                              backgroundColor: startQueueListener
                                  ? Colors.white
                                  : primaryColor,
                              buttonText: startQueueListener
                                  ? 'Cancel Queue'
                                  : 'Enter Queue',
                              borderColor:
                                  startQueueListener ? primaryColor : null,
                              textColor:
                                  startQueueListener ? primaryColor : softWhite,
                              onPressed: () {
                                if (startQueueListener) {
                                  isTimerActive = false;
                                  // queueTimer!.cancel();
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          actionsAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          actions: [
                                            PrimaryButton(
                                              onPressed: () {
                                                if (queueTimer != null &&
                                                    queueTimer!.isActive) {
                                                  queueTimer!.cancel();
                                                  print('Queue Timer canceled');
                                                }
                                                dequeuePosition();
                                                setState(() {
                                                  startQueueListener = false;
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              buttonText: 'Yes',
                                              backgroundColor: grayInputBox,
                                              textColor: blackColor,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: PrimaryButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isTimerActive = true;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                buttonText: 'No',
                                                backgroundColor: errorColor,
                                              ),
                                            ),
                                          ],
                                          title: Text('Cancel Queueing?'),
                                          content: Text(
                                              'Do you want to cancel your queue and leave your current spot?'),
                                          icon: Icon(
                                            Icons.warning,
                                            size: 48,
                                          ),
                                          iconColor: errorColor,
                                        );
                                      });
                                } else {
                                  setState(() {
                                    enqueuePosition();
                                    startQueueListener = true;
                                    isTimerActive = true;
                                  });
                                }
                              }),
                        ),
                      ],
                    );
                  });
                }),
              ),
            ),
          );
        });
  }

  Widget _initializeSheet(BuildContext context) {
    return Consumer<BookingProvider>(builder: (context, provider, child) {
      return SizedBox(
        height: ScreenUtil.parentHeight(context),
        child: DraggableScrollableSheet(
            controller: draggableController,
            shouldCloseOnMinExtent: false,
            initialChildSize: 0,
            minChildSize: 0,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.05],
            builder: (context, scrollcontroller) {
              return SingleChildScrollView(
                controller: scrollcontroller,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: ScreenUtil.parentWidth(context),
                          height: 40,
                          decoration: BoxDecoration(
                              color: isOnline ? primaryColor : grayColor,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16))),
                        ),
                        Container(
                          width: 80,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: ScreenUtil.parentHeight(context) * 0.75 - 35,
                      color: Colors.white,
                      child: isOnline == true && provider.values.isNotEmpty
                          ? ListView.builder(
                              itemCount: provider.values.length,
                              itemBuilder: (context, index) {
                                final item = provider.documentID;
                                String pickupLocation =
                                    '${provider.values[index]['Pickup Location']}';
                                String dropoffLocation =
                                    '${provider.values[index]['Dropoff Location']}';

                                return GestureDetector(
                                  onTap: () {
                                    _showDetailsOverlay(context, index);
                                    mainBookingIndex = index;
                                  },
                                  child: Container(
                                    key: ValueKey(item[index]),
                                    margin: const EdgeInsets.all(16),
                                    height: 340,
                                    decoration: BoxDecoration(
                                        boxShadow: const [
                                          BoxShadow(
                                            offset: Offset(4, 4),
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          )
                                        ],
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            width: 1.0, color: primaryColor)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 32.0),
                                              child: CircleAvatar(
                                                child: Icon(Icons.person),
                                              ),
                                            ),
                                            TextTitle(
                                              text:
                                                  '${provider.values[index]['Commuter Name']}',
                                              textColor: primaryColor,
                                              fontSize: 18,
                                            ),
                                          ],
                                        ),
                                        const Divider(
                                          color: grayInputBox,
                                          indent: 8,
                                          endIndent: 8,
                                          height: 0.5,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              alignment: Alignment.topLeft,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 32),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Pickup Location',
                                                    style: TextStyle(
                                                      color: grayColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    pickupLocation,
                                                    style: const TextStyle(
                                                      color: primaryColor,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(
                                              color: grayInputBox,
                                              endIndent: 24,
                                              indent: 24,
                                            ),
                                            Container(
                                              alignment: Alignment.topLeft,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 32),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Dropoff Location',
                                                    style: TextStyle(
                                                      color: grayColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    dropoffLocation,
                                                    style: const TextStyle(
                                                      color: accentColor,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        //
                                        CustomActionSlider(
                                          whileLoading: () {
                                            provider.stopListeningToDatabase();
                                            setState(() {
                                              isBookingOngoing = true;
                                            });
                                            _updateBookingDetails(index);
                                          },
                                          callBack: (actionController) {
                                            try {
                                              bookingSliderUpdateInfo(
                                                  provider, actionController);
                                            } catch (e) {
                                              print(e);
                                            }
                                          },
                                          onError: () {
                                            callSnackbar(
                                                'An error occured while doing this action. Please try again later.');
                                          },
                                        ),
                                        SizedBox(
                                            width: 200,
                                            child:
                                                LinearProgressIndicatorWithTimer(
                                              timeInMilliseconds: 1000,
                                              callBack: () {
                                                setState(() {
                                                  provider.values
                                                      .removeAt(index);
                                                  dequeuePosition();

                                                  // controlDraggable(
                                                  //     draggableController,
                                                  //     0,
                                                  //     Curves.easeOutCubic);
                                                  // setState(() {
                                                  //   enableQueueDraggable = true;
                                                  // });
                                                  // _jumpToNextDriver();
                                                  // provider.values
                                                  //     .removeAt(index);
                                                });
                                              },
                                            )),
                                      ],
                                    ),
                                  ),
                                );
                              })
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: ScreenUtil.parentWidth(context),
                                color: Colors.white,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/Bukyo.svg',
                                      colorFilter: const ColorFilter.mode(
                                          grayInputBox, BlendMode.srcIn),
                                    ),
                                    const TextTitle(
                                      text: 'No Bookings',
                                      textColor: grayInputBox,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),
      );
    });
  }

  Future<void> bookingSliderUpdateInfo(
      BookingProvider provider, ActionSliderController actionController) async {
    if (detailsOverlay != null) {
      removeOverlay(detailsOverlay);
    }
    final timeInMinutes = calculateEstimatedTimeOfArrival(
        LatLng(userLocation.latitude, userLocation.longitude),
        provider.pickupLatLng!);
    try {
      final isBookingStillAvailable = await provider.updateBookingValues(
        currentDocId,
        {
          "Driver UID": provider.bookingUserInfo['UID'],
          "Estimated Arrival Time": timeInMinutes,
          "Driver Name": provider.bookingUserInfo['Full Name'],
          "Driver Contact": provider.bookingUserInfo['Contact Number'],
          "Plate Number": provider.bookingUserInfo['Plate Number'],
          "Booking Status": "Ongoing",
          "Body Number": provider.bookingUserInfo['Body Number'],
        },
      );
      if (isBookingStillAvailable) {
        dequeuePosition();
        updateBooking(provider);
        sharedPreferences.addToCache({
          "Booking ID": currentDocId,
          "Zone": provider.bookingUserInfo['Zone Number']
        });
        _listenToBooking(currentDocId);

        controlDraggable(draggableController, 0, Curves.easeOut);
        controlDraggable(bookingDraggableController, 0.9, Curves.easeInCubic);
        // provider.stopListeningToDatabase();
      } else {
        callSnackbar('This booking has already been accepted.');
      }
    } catch (e) {
      actionController.failure();
      actionController.reset();
      print(e);
      callSnackbar(
          'An error occurred while accepting the booking. Please check your internet connection and try again later.');
    }
  }

  void _showDetailsOverlay(BuildContext context, int index) {
    _updateBookingDetails(index);

    detailsOverlay = OverlayEntry(builder: (context) {
      return Consumer<BookingProvider>(builder: (context, provider, child) {
        return OverlayEntryCard(
          animationController: animationController,
          height: ScreenUtil.parentHeight(context) * 0.75,
          width: ScreenUtil.parentWidth(context) * 0.90,
          titleText: 'Booking Details',
          onDismiss: () {
            provider.resetBookingInfo();
            if (detailsOverlay != null) {
              removeOverlay(detailsOverlay);
            }
          },
          actions: [
            if (!isBookingOngoing)
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 80,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(4, 4),
                          blurRadius: 4,
                          color: Colors.black26,
                        )
                      ]),
                  child: IconButton(
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (state) {
                          if (state.contains(WidgetState.pressed)) {
                            return Colors.transparent;
                          }
                          return null;
                        },
                      ),
                    ),
                    icon: const Icon(Icons.location_on_rounded),
                    color: softWhite,
                    onPressed: () async {
                      mapOperations(provider.documentID[index], provider);
                    },
                  ))
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookingInformationContent(
                pickupLocation: currentPickupLocation,
                dropoffLocation: currentDropoffLocation,
                bookingID: currentDocId,
                notes: currentNote,
                date: currentDate,
                time: currentTime,
              ),
              if (!isBookingOngoing)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: CustomActionSlider(onError: () {
                    callSnackbar(
                        'An error occured while doing this action. Please try again later.');
                  }, whileLoading: () {
                    provider.stopListeningToDatabase();
                    setState(() {
                      isBookingOngoing = true;
                    });
                    _updateBookingDetails(index);
                  }, callBack: (actionController) {
                    try {
                      bookingSliderUpdateInfo(provider, actionController);
                    } catch (e) {
                      print(e);
                    }
                  }),
                ),
            ],
          ),
        );
      });
    });

    Overlay.of(context, debugRequiredFor: widget).insert(detailsOverlay!);
    animationController.forward();
  }

  Widget showBookingDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0,
        minChildSize: 0,
        maxChildSize: 0.59,
        controller: bookingDraggableController,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              height: ScreenUtil.parentHeight(context) * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 4,
                      width: constraints.maxWidth * 0.3,
                      decoration: BoxDecoration(
                          color: grayInputBox,
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor,
                          radius: 24,
                          child: Icon(Icons.person), //need to add picture
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8),
                          child: SizedBox(
                            width: constraints.maxWidth * 0.42,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextTitle(
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  fontSize: 20,
                                  text: currentPassenger,
                                  textColor: blackColor,
                                ),
                                Text('Commuter'),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(accentColor)),
                          onPressed: () {
                            messageNumber(currentNumber);
                          },
                          icon: Icon(
                            Icons.message,
                            size: 18,
                          ),
                          color: Colors.white,
                        ),
                        IconButton(
                          onPressed: () {
                            callNumber(currentNumber);
                          },
                          icon: Icon(
                            Icons.call,
                            size: 18,
                          ),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const Divider(
                      height: 2,
                      color: grayInputBox,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: constraints.maxHeight * 0.5,
                        width: constraints.maxWidth * 0.9,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(width: 1, color: primaryColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.my_location_rounded,
                                    size: 32,
                                    color: primaryColor,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pickup Location',
                                      style: TextStyle(color: grayColor),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.7,
                                      child: TextTitle(
                                        maxLines: 2,
                                        text: currentPickupLocation,
                                        textColor: primaryColor,
                                        fontSize: 18,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(
                              height: 1,
                              color: grayInputBox,
                            ),
                            Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 32,
                                    color: accentColor,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dropoff Location',
                                      style: TextStyle(color: grayColor),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.7,
                                      child: TextTitle(
                                        textAlign: TextAlign.left,
                                        maxLines: 2,
                                        text: currentDropoffLocation,
                                        textColor: accentColor,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    //

                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     SizedBox(
                        //       height: 50,
                        //       width: constraints.maxWidth * 0.45,
                        //       child: PrimaryButton(
                        //         prefixIcon: const Icon(
                        //           Icons.call,
                        //           color: Colors.white,
                        //         ),
                        //         backgroundColor: primaryColor.withOpacity(0.7),
                        //         onPressed: () {
                        //           callNumber(currentNumber); //change number
                        //         },
                        //         buttonText: 'Call',
                        //       ),
                        //     ),
                        //     SizedBox(
                        //       height: 50,
                        //       width: constraints.maxWidth * 0.45,
                        //       child: PrimaryButton(
                        //         prefixIcon: const Icon(
                        //           Icons.message,
                        //           color: Colors.white,
                        //         ),
                        //         onPressedColor: accentColor,
                        //         backgroundColor: accentColor.withOpacity(0.7),
                        //         onPressed: () {
                        //           messageNumber(currentNumber); //change number
                        //         },
                        //         buttonText: 'Message',
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Consumer<BookingProvider>(
                              builder: (context, provider, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: constraints.maxWidth * 0.35,
                                  child: PrimaryButton(
                                    onPressedColor: warningColor.withBlue(4),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              actions: [
                                                SizedBox(
                                                  width: 90,
                                                  child: PrimaryButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      provider
                                                          .updateBookingValues(
                                                        currentDocId,
                                                        {
                                                          "Booking Status":
                                                              'Cancelled',
                                                          "Elapsed":
                                                              Timestamp.now(),
                                                        },
                                                        updateOngoingBookingStatus:
                                                            true,
                                                      );
                                                      _resetValues('Cancelled',
                                                          resetOnlineStatus:
                                                              true);

                                                      _addToBookingHistory(
                                                          context);
                                                    },
                                                    buttonText: 'Yes',
                                                    backgroundColor:
                                                        grayInputBox,
                                                    textColor: Colors.black,
                                                    onPressedColor:
                                                        grayColor.withRed(50),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 90,
                                                  child: PrimaryButton(
                                                    onPressedColor:
                                                        errorColor.withRed(50),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    buttonText: 'No',
                                                    backgroundColor: errorColor,
                                                  ),
                                                ),
                                              ],
                                              title: const TextTitle(
                                                text: 'Cancel Booking',
                                                textColor: errorColor,
                                              ),
                                              icon: const Icon(
                                                Icons.warning,
                                                size: 40,
                                              ),
                                              iconColor: errorColor,
                                              content: const Text(
                                                  'Are you sure you want to cancel this booking?'),
                                            );
                                          });
                                    },
                                    buttonText: 'Cancel',
                                    backgroundColor: errorColor,
                                  ),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: constraints.maxWidth * 0.55,
                                  child: PrimaryButton(
                                    onPressed: () {
                                      // if (completeButton) {
                                      //

                                      showDialog(
                                          context: context,
                                          builder: (c) {
                                            return CustomAlertDialog(
                                                iconSize: 50,
                                                alertIcon: Icons.check_circle,
                                                iconAndButtonColor:
                                                    primaryColor,
                                                title: 'Booking Complete',
                                                content:
                                                    'Trip successfully completed. Awaiting your next assignment!',
                                                buttonText: 'OK',
                                                onclick: () {
                                                  Navigator.pop(c);
                                                  provider.updateBookingValues(
                                                    currentDocId,
                                                    {
                                                      "Booking Status":
                                                          'Completed',
                                                      "Elapsed":
                                                          Timestamp.now(),
                                                    },
                                                    updateOngoingBookingStatus:
                                                        true,
                                                  );
                                                  _resetValues('Completed',
                                                      resetOnlineStatus: true);
                                                });
                                          });
                                      // }
                                    },
                                    buttonText: 'Finish Booking',
                                    backgroundColor: completeButton
                                        ? primaryColor
                                        : grayInputBox,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );
        });
  }

  void mapOperations(String id, BookingProvider provider) async {
    print(id);

    DirectionsClass directions = DirectionsClass(provider);

    if (provider.BookingPolylineList.containsKey(id)) {
      print('using the cache polyline');

      provider.resetPolyline();
      List<LatLng> cachedPolyline =
          List<LatLng>.from(provider.BookingPolylineList[id]!);

      provider.addPolylineListToPolyline(cachedPolyline);

      // print(provider.bookingPolyline);
    } else {
      directions.decodePolyline(currentPolyline);
      String newId = id;
      provider.BookingPolylineList.putIfAbsent(
          newId, () => directions.bookingPolyline);

      debugPrint("${provider.BookingPolylineList}");
    }
    if (detailsOverlay != null) {
      removeOverlay(detailsOverlay);
    }
    controlDraggable(draggableController, 0, Curves.easeOutCubic);

    mainMapKey.currentState!.focusCameraToLocation(provider.pickupLatLng!);
  }

  void updateBooking(BookingProvider provider) {
    mainMapKey.currentState!.showCurrentLocation = false;
    if (provider.BookingPolylineList.containsKey(currentDocId)) {
      List<LatLng> cachedPolyline =
          List<LatLng>.from(provider.BookingPolylineList[currentDocId]!);
      provider.addPolylineListToPolyline(cachedPolyline);
    } else {
      DirectionsClass directions = DirectionsClass(provider);
      directions.decodePolyline(currentPolyline);
    }
    setState(() {
      isBookingOngoing = true;
    });

    currentLocationSubscription =
        Geolocator.getPositionStream().listen((currentPosition) {
      mainMapKey.currentState!.bookingCameraWithTracking(
          LatLng(currentPosition.latitude, currentPosition.longitude));

      // _addingMarkerToPosition(currentPosition, provider);
      //add icon
      //updateValues position naman
      // if (isLocationWithinBounds(
      //         LatLng(currentPosition.latitude, currentPosition.longitude),
      //         provider.dropoffLatLng!,
      //         50) &&
      //     completeButton == false) {
      //   setState(() {
      //     completeButton = true;
      //   });
      // }
    });

    BookingHistoryProvider historyProvider =
        Provider.of<BookingHistoryProvider>(context, listen: false);

    historyProvider.onGoingBooking({
      "Pickup Location": currentPickupLocation,
      "Dropoff Location": currentDropoffLocation,
      "Note": currentNote,
      "Booking ID": currentDocId,
      "Time": currentTime,
      "Date": currentDate,
    });
  }

  void _resetValues(String status, {bool resetOnlineStatus = false}) {
    BookingProvider provider =
        Provider.of<BookingProvider>(context, listen: false);
    setState(() {
      bookingStatus = status;
      isBookingOngoing = false;
    });
    controlDraggable(bookingDraggableController, 0, Curves.easeOutCubic);
    // Navigator.of(context).pop();
    // if (!resetOnlineStatus) {
    //   // controlDraggable(draggableController, 0.9, Curves.easeInCubic);
    //   // provider.listenToBookingDatabaseValues();
    //   controlDraggable(queueDraggable, 0.9, Curves.easeInOutCubic);
    //   provider.stopListeningToDatabase();
    // }
    provider.resetBookingInfo();
    sharedPreferences.deleteCache("Booking ID");
    MarkerId riderMarkerId = const MarkerId('Rider Position ID');
    bool markerExists = provider.pinnedMarkers
        .any((marker) => marker.markerId == riderMarkerId);
    if (markerExists) {
      Marker oldMarker = provider.pinnedMarkers
          .firstWhere((marker) => marker.markerId == riderMarkerId);
      provider.pinnedMarkers.remove(oldMarker);
    }
    BookingHistoryProvider history =
        Provider.of<BookingHistoryProvider>(context, listen: false);
    if (resetOnlineStatus) {
      setState(() {
        isOnline = false;
      });
    }
    history.ongoingBooking.clear();
  }

  void _addToBookingHistory(BuildContext context) {
    BookingHistoryProvider history =
        Provider.of<BookingHistoryProvider>(context, listen: false);
    history.addToHistory({
      "Pickup Location": currentPickupLocation,
      "Dropoff Location": currentDropoffLocation,
      "Note": currentNote,
      "Booking ID": currentDocId,
      "Time": currentTime,
      "Date": currentDate,
      "Status": bookingStatus,
    });
    if (history.ongoingBooking.isNotEmpty) {
      history.ongoingBooking.clear();
    }

    if (currentLocationSubscription != null) {
      currentLocationSubscription!.cancel();
      mainMapKey.currentState!.showCurrentLocation = true;
    }
  }

  void _loadSharedPreferences() async {
    BookingProvider provider =
        Provider.of<BookingProvider>(context, listen: false);
    final user = {
      "UID": await sharedPreferences.readCacheString("UID"),
      "Full Name": await sharedPreferences.readCacheString('Full Name'),
      "Contact Number":
          await sharedPreferences.readCacheString('Contact Number'),
      "Body Number": await sharedPreferences.readCacheString('Body Number'),
      "Zone Number": await sharedPreferences.readCacheString('Zone Number'),
      "Plate Number": await sharedPreferences.readCacheString('Plate Number'),
      "Vehicle Type": await sharedPreferences.readCacheString('Vehicle Type'),
    };
    provider.updateBookingUserInfo(user);
  }

  void _addingMarkerToPosition(
      Position currentPosition, BookingProvider provider) {
    MarkerId riderMarkerId = const MarkerId('Rider Position ID');
    bool markerExists = provider.pinnedMarkers
        .any((marker) => marker.markerId == riderMarkerId);
    if (markerExists) {
      Marker oldMarker = provider.pinnedMarkers
          .firstWhere((marker) => marker.markerId == riderMarkerId);
      provider.pinnedMarkers.remove(oldMarker);
      provider.addToPinnedMarkers(
        Marker(
          markerId: riderMarkerId,
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          flat: true,
        ),
      );
    } else {
      provider.addToPinnedMarkers(
        Marker(
          markerId: riderMarkerId,
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
        ),
      );
    }
  }

  String _getFirstNameInFirstSpace(String bookingUserInfo) {
    return bookingUserInfo.split(' ')[0];
  }

  Future<void> getCurrentPos() async {
    userLocation = (await getCurrentLocation())!;
  }

  bool locationIsInTerminal() {
    BookingProvider provider =
        Provider.of<BookingProvider>(context, listen: false);
    final zoneRef = provider.bookingUserInfo['Zone Number'];
    return terminals.where((terminal) => terminal.zone == zoneRef).any(
        (terminal) => isLocationWithinBounds(
            LatLng(userLocation.latitude, userLocation.longitude),
            terminal.coordinates,
            100));
  }

  void _updateBookingDetails(int index) {
    BookingProvider provider = _getProvider();
    provider.resetBookingInfo();
    provider.updatePickup(
        provider.riderPickupAddress(index), provider.getPickupLatLng(index));
    provider.updateDropoff(
        provider.riderDropoffAddress(index), provider.getDropOffLatLng(index));

    currentPickupLocation = provider.pickupLocation;
    currentDropoffLocation = provider.dropoffLocation;
    currentPolyline = provider.values[index]['Polyline Code'];
    currentNote = '${provider.values[index]['Note']}';
    currentDocId = provider.documentID[index];
    currentDate = provider.getDateStamp(index);
    currentTime = provider.getTimeStamp(index);
    currentPassenger = '${provider.values[index]['Commuter Name']}';
    currentNumber = '${provider.values[index]['Contact Number']}';
  }

  BookingProvider _getProvider() {
    return Provider.of<BookingProvider>(context, listen: false);
  }

  Future<void> enqueuePosition() async {
    final provider = _getProvider();
    final bodyNumber = provider.bookingUserInfo['Body Number'];
    final zone = provider.bookingUserInfo['Zone Number'];

    final queueBodyNumberExists =
        await firestoreOperations.retrieveCollectionSnapshots('Queue',
            documentPath: zone,
            subCollectionPath: '${provider.currentTerminal} Queue',
            where: 'Body Number',
            equalTo: bodyNumber);

    if (queueBodyNumberExists.docs.isNotEmpty) {
      firestoreOperations.updateDatabaseValues(
          'Queue',
          zone,
          {
            'Queue Position': Timestamp.now().millisecondsSinceEpoch,
            'Available': true,
          },
          subCollectionPath: '${provider.currentTerminal} Queue',
          subDocumentPath: queueBodyNumberExists.docs.first.id);
      provider.updateQueueID(queueBodyNumberExists.docs[0].id);
      sharedPreferences.addToCache({
        "Queue ID": queueBodyNumberExists.docs[0].id,
      });
    } else {
      firestoreOperations.addDataToDatabase(
        'Queue',
        documentPath: zone,
        subCollectionPath: '${provider.currentTerminal} Queue',
        {
          'Driver Name': provider.bookingUserInfo['Full Name'],
          'Body Number': provider.bookingUserInfo['Body Number'],
          'Queue Position': Timestamp.now().millisecondsSinceEpoch,
          'Available': true,
        },
        onCompleteAdd: (id) {
          provider.updateQueueID(id);
          sharedPreferences.addToCache({
            "Queue ID": id,
          });
        },
      );
    }
  }

  Future<void> dequeuePosition() async {
    final provider = _getProvider();
    final zone = provider.bookingUserInfo['Zone Number'];
    firestoreOperations.updateDatabaseValues(
        'Queue',
        zone,
        {
          'Available': false,
          'Queue Position': Timestamp.now().millisecondsSinceEpoch,
        },
        subCollectionPath: '${provider.currentTerminal} Queue',
        subDocumentPath: provider.queueID);
  }

  void _getTerminal() {
    final provider = _getProvider();
    for (var terminal in terminals) {
      if (isLocationWithinBounds(
          LatLng(userLocation.latitude, userLocation.longitude),
          terminal.coordinates,
          30)) {
        provider.updateTerminal(terminal.terminalName);
      }
    }
  }

  Stream<int?> queueListener() {
    final provider = _getProvider();

    return FirebaseFirestore.instance
        .collection('Queue')
        .doc(provider.bookingUserInfo['Zone Number'])
        .collection('${provider.currentTerminal} Queue')
        .snapshots()
        .map((querySnapshot) {
      final queriedDocs = querySnapshot.docs
          .where((doc) => doc.data()['Available'] == true)
          .toList();

      queriedDocs.sort(
        (a, b) {
          final docA = a.data()['Queue Position'] as int;
          final docB = b.data()['Queue Position'] as int;

          return docA.compareTo(docB);
        },
      );

      for (int index = 0; index < queriedDocs.length; index++) {
        final doc = queriedDocs[index].data() as Map<String, dynamic>;
        if (doc['Body Number'] == provider.bookingUserInfo['Body Number']) {
          return index;
        }
      }
      return queriedDocs.length;
    });
  }

  void reloadTerminatedBooking() async {
    final provider = _getProvider();
    final bookingID = await sharedPreferences.readCacheString("Booking ID");
    final zone = await sharedPreferences.readCacheString("Zone");
    if (bookingID != null &&
        bookingID.isNotEmpty &&
        zone != null &&
        zone.isNotEmpty) {
      print(bookingID);

      try {
        final booking = await firestoreOperations.retrieveDatabaseValues(
          'Booking_Details',
          bookingID,
        );
        if (booking['Booking Status'] == 'Ongoing') {
          setState(() {
            isOnline = true;
          });
          provider.values.add(booking);
          provider.documentID.add(bookingID);
          Future.delayed(Duration(seconds: 1), () {
            _updateBookingDetails(0);
            updateBooking(provider);
          });

          Future.delayed(Duration(seconds: 1), () {
            controlDraggable(bookingDraggableController, 1, Curves.easeInCirc);
          });
        }
      } catch (e) {
        throw Exception(e);
      }
    }
  }

  void _listenToBooking(String currentDocId) {
    print(currentDocId);
    FirebaseFirestore.instance
        .collection('Booking_Details')
        .doc(currentDocId)
        .snapshots()
        .listen((snapshot) {
      print('listening..');
      final data = snapshot.data();
      if (data != null && data['Booking Status'] == 'Cancelled') {
        if (!_hasShownCancelledDialog) {
          _hasShownCancelledDialog = true;
          showDialog(
            context: context,
            builder: (context) {
              return CustomAlertDialog(
                iconAndButtonColor: errorColor,
                title: 'Booking Cancelled',
                content: 'This booking has been cancelled.',
                onclick: () {
                  Navigator.of(context).pop();
                  _resetValues('Cancelled', resetOnlineStatus: true);
                },
              );
            },
          );
        }
      }
    });
  }
}
