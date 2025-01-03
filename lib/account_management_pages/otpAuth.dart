import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/account_management_pages/login.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/roleCheck.dart';
import 'package:flutter_try_thesis/driver/rider_main_screen/riderMainScreen.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/backButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/customCard.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/linkText.dart';
import 'package:flutter_try_thesis/constants/logoMain.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/cache_manager/sharedPreferences/userSharedPreferences.dart';
import 'package:flutter_try_thesis/models/providers/userProvider.dart';
import 'package:flutter_try_thesis/routing/router.dart';
import 'package:flutter_try_thesis/commuter/commuter_screen/mainScreenWithMap.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpPage extends StatefulWidget {
  final String contactNumber;
  final bool isRider;
  final Map<String, dynamic>? userInfo;
  final Map<String, dynamic>? vehicleData;

  const OtpPage({
    super.key,
    required this.contactNumber,
    this.isRider = false,
    this.userInfo,
    this.vehicleData,
  });

  @override
  OtpPageState createState() => OtpPageState();
}

class OtpPageState extends State<OtpPage> {
  final firebaseAuth = FirebaseAuth.instance;
  String _verificationID = '';
  bool isResendEnable = true;
  int countdownCount = 60;
  Timer? globalTimer;
  TextEditingController otpController = TextEditingController();
  Timer? debounce;
  int? _resendToken;

  UserSharedPreferences sharedPreferences = UserSharedPreferences();
  @override
  void initState() {
    _accountAuthenticated();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Form(
            child: Stack(
              children: [
                const BackgroundWithColor(),
                Positioned(
                  top: 24,
                  left: 8,
                  child: BackbuttoninForm(
                    onPressed: () {
                      MyRouter.navigateToPrevious(context);
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      height: ScreenUtil.parentHeight(context) * 0.20,
                      alignment: Alignment.center,
                      child: MainLogo(logoHeight: 70, logoWidth: 200),
                    ),
                    CustomizedCard(
                      cardWidth: ScreenUtil.parentWidth(context),
                      cardHeight: ScreenUtil.parentHeight(context) * 0.80,
                      cardRadius: 50,
                      childWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.lock_clock_outlined,
                                size: ScreenUtil.parentHeight(context) * 0.20,
                                color: primaryColor,
                              ),
                              const TextTitle(
                                text: 'Enter Code',
                                textColor: primaryColor,
                              ),
                              Text(
                                'Enter the 6-digit code that we sent to ${_filteredNumber()}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 60,
                                    width:
                                        ScreenUtil.parentWidth(context) * 0.8,
                                    child: PinCodeTextField(
                                      cursorColor: primaryColor,
                                      keyboardType: TextInputType.number,
                                      pinTheme: PinTheme(
                                        borderRadius: BorderRadius.circular(8),
                                        inactiveBorderWidth: 0.5,
                                        activeBorderWidth: 0.5,
                                        selectedBorderWidth: 0.5,
                                        inactiveColor: grayColor,
                                        activeColor: secondaryColor,
                                        selectedColor: accentColor,
                                        shape: PinCodeFieldShape.box,
                                      ),
                                      appContext: context,
                                      length: 6,
                                      controller: otpController,
                                    ),
                                  )
                                  // FieldOTPUtil(
                                  //     callBack: (input) {
                                  //       otpInput = input!;
                                  //     },
                                  //     fieldHeight: 60,
                                  //     fieldWidth:
                                  //         ScreenUtil.parentWidth(context) *
                                  //             0.11),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Didn\'t receive the code?'),
                                  isResendEnable
                                      ? TextLink(
                                          onPressed: () {
                                            _accountAuthenticated(resend: true);
                                          },
                                          linktext: 'Resend Code',
                                          textDecoration:
                                              TextDecoration.underline,
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Resend in $countdownCount seconds.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                          PrimaryButton(
                            onPressed: () async {
                              if (debounce?.isActive ?? false) {
                                debounce?.cancel();
                              }
                              debounce = Timer(Duration(seconds: 1), () {
                                if (otpController.text.isNotEmpty) {
                                  showDialog(
                                      barrierDismissible: false,
                                      barrierColor:
                                          const Color.fromARGB(31, 77, 51, 51),
                                      context: context,
                                      builder: (context) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: accentColor,
                                          ),
                                        );
                                      });
                                  verifyOTP(otpController.text);
                                }
                              });
                            },
                            buttonText: 'Verify',
                            textColor: Colors.white,
                            borderRadius: 8,
                            backgroundColor: primaryColor,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void resendCooldown() {
    final DateTime endTime =
        DateTime.now().add(Duration(seconds: countdownCount));

    setState(() {
      isResendEnable = false;
    });

    Timer.periodic(const Duration(seconds: 1), (time) {
      final remainingTime = endTime.difference(DateTime.now()).inSeconds;

      if (remainingTime <= 0) {
        time.cancel();
        setState(() {
          isResendEnable = true;
          countdownCount = 60;
        });
      } else {
        if (mounted) {
          setState(() {
            countdownCount = remainingTime;
          });
        }
      }
    });
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationID == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session expired. Please request a new OTP.'),
      ));
      return;
    }

    PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
      verificationId: _verificationID,
      smsCode: otp,
    );

    try {
      final userCredential =
          await firebaseAuth.signInWithCredential(authCredential);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        if (widget.userInfo == null) {
          addUser(uid);
        }
        await Future.delayed(Duration(seconds: 5));

        Navigator.of(context).pop();
        _navigateToNextScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sign-in failed. Please try again later.'),
        ));
        Navigator.of(context).pop();
      }
      // _checkRole();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid OTP. Please try again later.'),
        ));
        Navigator.of(context).pop();
      } else if (e.code == 'session-expired') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session expired. Please try again later.'),
        ));
        Navigator.of(context).pop();
      } else if (e.code == 'network-request-failed') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please check your internet connection and try again.'),
        ));
        Navigator.of(context).pop();
      } else if (e.code == 'channel-error') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error connecting to the server. Please try again later'),
        ));
        print(e.code);
        print(e.message);
        Navigator.of(context).pop();
      } else {
        print(e.message);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The sms code has expired. Please try again later.'),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please check your internet connection and try again.'),
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> _accountAuthenticated({bool resend = false}) async {
    String contactNumber = widget.contactNumber;
    await Future.delayed(Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please wait...'),
      ));
      resendCooldown();
    });

    try {
      await firebaseAuth.verifyPhoneNumber(
        forceResendingToken: resend ? _resendToken : null,
        phoneNumber: contactNumber,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (credentials) async {
          await firebaseAuth.signInWithCredential(credentials);
          final uid = firebaseAuth.currentUser!.uid;
          if (widget.userInfo == null) {
            addUser(uid);
          }
          // _checkRole();
        },
        verificationFailed: (authException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Verification Failed. ${authException.message}')));
        },
        codeSent: (id, token) {
          setState(() {
            _verificationID = id;
            _resendToken = token;
          });
          resendCooldown();
        },
        codeAutoRetrievalTimeout: (id) {
          setState(() {
            _verificationID = id;
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
      if (e.code == 'invalid-verification-code') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error verifying OTP. Please try again.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please check your internet connection and try again.'),
      ));
    }
  }

  void addUser(String uid) {
    final userProvider = getProvider();
    userProvider.addUserToDatabase(uid, isDriver: widget.isRider);
  }

  // void _checkRole() {
  //   final userProvider = getProvider();
  //   final role = userProvider.userInfo['Role'];
  //   RoleCheck userRoleCheck = RoleCheck(
  //     userRoles: role,
  //   );
  //   userRoleCheck.showRoleCheckDialog(context);
  // }

  UserProvider getProvider() {
    return Provider.of<UserProvider>(context, listen: false);
  }

  Future<void> _navigateToNextScreen() async {
    final userProvider = getProvider();
    if (widget.userInfo != null) {
      userProvider.updateUserInfo(
          widget.userInfo!['Full Name'], widget.userInfo!['Contact Number']);
      sharedPreferences.addToCache({
        "UID": widget.userInfo!['UID'],
      });
      if (widget.vehicleData != null) {
        userProvider.updateVehicleInfo(
            widget.vehicleData!['Operator Name'],
            widget.vehicleData!['Ownership Type'],
            widget.vehicleData!['Body Number'],
            widget.vehicleData!["MTOP Number"],
            widget.vehicleData!['License Number'],
            widget.vehicleData!['Plate Number'],
            widget.vehicleData!['Vehicle Type'],
            widget.vehicleData!['Chassis Number'],
            widget.vehicleData!['Zone Number']);
      }
      if (widget.isRider) {
        MyRouter.navigateAndRemoveAllStackBehind(
            context, const RiderScreenMap());
      } else {
        MyRouter.navigateAndRemoveAllStackBehind(
            context, const MainScreenWithMap());
      }
    } else {
      MyRouter.navigateAndRemoveAllStackBehind(context, const LoginForm());
    }
  }

  String _filteredNumber() {
    return '${widget.contactNumber.substring(0, 4)}*****${widget.contactNumber.substring(9)}';
  }
}
