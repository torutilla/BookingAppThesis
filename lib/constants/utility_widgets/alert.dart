import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData alertIcon;
  final String buttonText;
  final double iconSize;

  final VoidCallback onclick;
  final Color iconAndButtonColor;
  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.alertIcon = Icons.info,
    this.buttonText = 'OK',
    required this.onclick,
    this.iconAndButtonColor = primaryColor,
    this.iconSize = 70,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      alignment: Alignment.center,
      actions: [
        SizedBox(
          width: 90,
          child: PrimaryButton(
            onPressed: onclick,
            buttonText: buttonText,
            backgroundColor: iconAndButtonColor,
            onPressedColor: iconAndButtonColor,
          ),
        ),
      ],
      title: Text(title),
      titleTextStyle: TextStyle(
          color: iconAndButtonColor, fontSize: 25, fontWeight: FontWeight.w700),
      content: Text(
        content,
        textAlign: TextAlign.center,
      ),
      icon: Icon(
        alertIcon,
        size: iconSize,
      ),
      iconColor: iconAndButtonColor,
    );
  }
}
