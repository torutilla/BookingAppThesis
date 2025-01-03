import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/account_management_pages/login.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/customCard.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/textFields.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/providers/argon2.dart';
import 'package:flutter_try_thesis/routing/router.dart';

class ForgotPassword extends StatefulWidget {
  final String? contactNumber;
  const ForgotPassword({super.key, this.contactNumber});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  PasswordHashArgon2 argon2 = PasswordHashArgon2();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const BackgroundWithColor(),
                CustomizedCard(
                    cardRadius: 24,
                    cardWidth: ScreenUtil.parentWidth(context),
                    cardHeight: ScreenUtil.parentHeight(context) * 0.9,
                    childWidget: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Column(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              color: primaryColor,
                              size: 140,
                            ),
                            TextTitle(
                              text: 'Create new password',
                              textColor: accentColor,
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Enter a new password to regain access to your account. Make it secure and easy to remember.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            TextFieldFormat(
                              borderRadius: 8,
                              fieldHeight: 90,
                              fieldWidth: ScreenUtil.parentWidth(context) * 0.8,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Field can\'t be empty';
                                }
                                if ((value.length < 8 || value.length > 16)) {
                                  return 'Password must be 8-16 characters long';
                                }
                                return null;
                              },
                              controller: passwordController,
                              formText: 'Password',
                            ),
                            TextFieldFormat(
                              borderRadius: 8,
                              fieldHeight: 90,
                              fieldWidth: ScreenUtil.parentWidth(context) * 0.8,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Field can\'t be empty';
                                }
                                if (passwordController.text !=
                                    confirmPasswordController.text) {
                                  return 'Password do not match.';
                                }
                                return null;
                              },
                              controller: confirmPasswordController,
                              formText: 'Confirm Password',
                            ),
                          ],
                        ),
                        PrimaryButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              //password
                              try {
                                FirebaseFirestore firestore =
                                    FirebaseFirestore.instance;
                                final user = await firestore
                                    .collection('Users')
                                    .where('Contact Number',
                                        isEqualTo: widget.contactNumber)
                                    .limit(1)
                                    .get();

                                final salt = argon2.generateRandomSalt();
                                final password = argon2.generateHashedPassword(
                                    passwordController.text, salt);
                                firestore
                                    .collection('Users')
                                    .doc(user.docs[0].id)
                                    .update({"Hash": password, "Salt": salt});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Something went wrong. Please try again later.')));
                              }
                              MyRouter.navigateAndRemoveAllStackBehind(
                                  context, LoginForm());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Some inputs are invalid. Please check your entries and try again.')));
                            }
                          },
                          buttonText: 'Confirm',
                        )
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
