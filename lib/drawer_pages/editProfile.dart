import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/textFields.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';

class EditProfile extends StatefulWidget {
  final bool isDriver;
  const EditProfile({super.key, this.isDriver = false});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: () {},
        shape: CircleBorder(),
        child: Icon(Icons.save),
      ),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          style: ButtonStyle(backgroundColor: WidgetStateColor.transparent),
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: softWhite,
              ),
        ),
      ),
      body: SingleChildScrollView(
          child: widget.isDriver ? DriverEditProfile() : CommuterEditProfile()),
    );
  }
}

class CommuterEditProfile extends StatefulWidget {
  const CommuterEditProfile({super.key});

  @override
  State<CommuterEditProfile> createState() => _CommuterEditProfileState();
}

class _CommuterEditProfileState extends State<CommuterEditProfile> {
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: null,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: ScreenUtil.parentWidth(context),
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    BackgroundWithColor(),
                    CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 48,
                      ),
                      radius: 54,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextTitle(
                        text: 'Personal Information',
                        textColor: primaryColor,
                      ),
                    ),
                    Text('Full Name'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 80,
                          width: ScreenUtil.parentWidth(context) - 90,
                          child: TextFieldFormat(
                            enabled: false,
                            controller: nameController,
                            borderRadius: 8,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),
                    Text('Contact Number'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 80,
                          width: ScreenUtil.parentWidth(context) - 90,
                          child: TextFieldFormat(
                            enabled: false,
                            controller: nameController,
                            borderRadius: 8,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}

class DriverEditProfile extends StatefulWidget {
  const DriverEditProfile({super.key});

  @override
  State<DriverEditProfile> createState() => _DriverEditProfileState();
}

class _DriverEditProfileState extends State<DriverEditProfile> {
  TextEditingController nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: null,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: ScreenUtil.parentWidth(context),
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    BackgroundWithColor(),
                    CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 48,
                      ),
                      radius: 54,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTitle(
                      text: 'Personal Information',
                      textColor: primaryColor,
                    ),
                    Text('Full Name'),
                    SizedBox(
                      height: 80,
                      width: ScreenUtil.parentWidth(context),
                      child: TextFieldFormat(
                        enabled: false,
                        controller: nameController,
                        borderRadius: 8,
                      ),
                    ),
                    Text('Contact Number'),
                    SizedBox(
                      height: 80,
                      width: ScreenUtil.parentWidth(context),
                      child: TextFieldFormat(
                        enabled: false,
                        controller: nameController,
                        borderRadius: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
