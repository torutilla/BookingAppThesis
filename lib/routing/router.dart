import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_try_thesis/account_management_pages/login.dart';
import 'package:flutter_try_thesis/account_management_pages/uploadID.dart';
import 'package:flutter_try_thesis/admin/pages/adminPage.dart';
import 'package:flutter_try_thesis/commuter/booking_management/bookingDetails.dart';
import 'package:flutter_try_thesis/commuter/commuter_screen/mainScreenWithMap.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/driver/account_management/rider_page/vehicleRegistration.dart';
import 'package:flutter_try_thesis/driver/rider_main_screen/riderMainScreen.dart';
import 'package:flutter_try_thesis/models/cache_manager/sharedPreferences/userSharedPreferences.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:flutter_try_thesis/models/providers/historyProvider.dart';
import 'package:flutter_try_thesis/models/providers/userProvider.dart';

import 'package:flutter_try_thesis/startup.dart';
import 'package:provider/provider.dart';

import '../constants/logoMain.dart';
import '../constants/utility_widgets/background.dart';
import '../models/navigatorKey.dart';
import '../models/providers/adminProviders.dart';

class MyRouter extends StatelessWidget {
  MyRouter({super.key});
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  UserSharedPreferences sharedPreferences = UserSharedPreferences();
  String? initialScreen;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return FutureBuilder<String?>(
        future: determineUserSession(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return MaterialApp(
          //     debugShowCheckedModeBanner: false,
          //     home: BackgroundWithColor(
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           MainLogo(logoHeight: 70, logoWidth: 70),
          //           const Padding(
          //             padding: EdgeInsets.all(8.0),
          //             child: CircularProgressIndicator(
          //               color: Colors.white,
          //             ),
          //           )
          //         ],
          //       ),
          //     ),
          //   );
          // }

          final initialRoute = snapshot.data;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => BookingProvider(),
              ),
              ChangeNotifierProvider(
                create: (context) => SuggestionsProvider(),
              ),
              ChangeNotifierProvider(
                  create: (context) => BookingHistoryProvider()),
              ChangeNotifierProvider(create: (context) => UserProvider()),
              ChangeNotifierProvider(
                create: (context) => AdminProvider(),
              ),
            ],
            child: MaterialApp(
              navigatorKey: NavigationService.navigatorKey,
              theme: ThemeData(
                iconButtonTheme: IconButtonThemeData(
                    style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(primaryColor))),
                dropdownMenuTheme: DropdownMenuThemeData(
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w400),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: const TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w400),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: primaryColor,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                actionIconTheme: ActionIconThemeData(
                  backButtonIconBuilder: (context) {
                    return IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          color: Colors.white,
                        ));
                  },
                ),
                textButtonTheme: const TextButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(softWhite),
                    elevation: WidgetStatePropertyAll(8),
                    shadowColor: WidgetStatePropertyAll(Colors.black26),
                  ),
                ),
                dividerTheme: const DividerThemeData(
                  color: grayInputBox,
                  endIndent: 8,
                  indent: 8,
                  thickness: 1,
                ),
                iconTheme: const IconThemeData(
                  color: softWhite,
                ),
                colorScheme: const ColorScheme(
                    brightness: Brightness.light,
                    primary: primaryColor,
                    onPrimary: softWhite,
                    secondary: secondaryColor,
                    onSecondary: softWhite,
                    error: errorColor,
                    onError: softWhite,
                    surface: softWhite,
                    onSurface: Colors.black),
                appBarTheme: const AppBarTheme(
                  color: primaryColor,
                ),
                textTheme: const TextTheme(
                  titleLarge: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-Bold.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                  titleMedium: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-SemiBold.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                  titleSmall: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-SemiBold.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  bodyLarge: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-Bold.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                  bodyMedium: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-Medium.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 16,
                    fontWeight: FontWeight.w200,
                  ),
                  bodySmall: TextStyle(
                    fontFamily: 'assets/Fonts/Inter_28pt-Light.ttf',
                    decoration: TextDecoration.none,
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
              initialRoute: 'Map',
              // initialRoute,
              routes: {
                'Admin': (context) => const AdminMainScreen(),
                'imgupload': (context) => const UploadIDCard(),
                '/': (context) => const StartUpApp(),
                'Vehicle': (context) => const VehicleRegistration(),
                'Map': (context) => const MainScreenWithMap(),
                'Booking Details': (context) => const BookingDetails(),
                'Rider': (context) => const RiderScreenMap(),
                'Login': (context) => const LoginForm(),
              },
            ),
          );
        });
  }

  static void navigateToNext(BuildContext context, Widget nextClass) {
    Navigator.push(context, pageRouteWithSlideAnimation(nextClass));
  }

  static void navigateToNextNoTransition(
      BuildContext context, Widget nextClass) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextClass),
    );
  }

  static void navigateToNextPermanent(BuildContext context, Widget nextClass) {
    Navigator.pushReplacement(context, pageRouteWithSlideAnimation(nextClass));
  }

  static void navigateAndRemoveAllStackBehind(
      BuildContext context, Widget nextClass) {
    Navigator.pushAndRemoveUntil(
      context,
      pageRouteWithSlideAnimation(nextClass),
      (route) => false,
    );
  }

  static void navigateToPrevious(BuildContext context) {
    Navigator.pop(context);
  }

  Future<String?> determineUserSession() async {
    await Future.delayed(const Duration(seconds: 5));
    final user = firebaseAuth.currentUser;
    if (user != null) {
      final route = await sharedPreferences.readCacheString('Initial Screen');
      print(route);
      return route;
    } else {
      print('user is null');
    }
    return '/';
  }
}

Route pageRouteWithSlideAnimation(Widget className) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => className,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.fastEaseInToSlowEaseOut;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
