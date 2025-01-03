import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/backButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/dropDownMenu.dart';

import 'package:flutter_try_thesis/constants/utility_widgets/textFields.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/constants.dart';
import '../../constants/screenSizes.dart';

class MyFeedbacks extends StatefulWidget {
  const MyFeedbacks({
    super.key,
  });

  @override
  State<MyFeedbacks> createState() => _MyFeedbacksState();
}

class _MyFeedbacksState extends State<MyFeedbacks> {
  OverlayEntry? overlayDatePicker;
  TextEditingController dateController = TextEditingController();
  TextEditingController bodyNumberController = TextEditingController();
  TextEditingController driverNameController = TextEditingController();
  TextEditingController zoneController = TextEditingController();
  List<String> zoneList = [
    'Zone 1',
    'Zone 1-A',
    'Zone 1-B',
    'Zone 1-C',
    'Zone 1-D',
    'Zone 2',
    'Zone 2-A',
    'Zone 3',
    'Zone 3-A',
    'Zone 4',
    'Zone 4-A',
  ];

  bool anonymous = false;
  double starValue = 1;

  String uid = '';
  @override
  void initState() {
    super.initState();
    _getUID();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
            selectionColor: secondaryColor.withOpacity(0.5),
            cursorColor: primaryColor),
        colorScheme: ColorScheme(
            brightness: Theme.of(context).brightness,
            primary: primaryColor,
            onPrimary: Colors.white,
            secondary: accentColor,
            onSecondary: Colors.white,
            error: errorColor,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black),
        datePickerTheme: DatePickerThemeData(
          dividerColor: grayInputBox,
          backgroundColor: Colors.white,
          dayOverlayColor: WidgetStatePropertyAll(
            secondaryColor.withOpacity(0.5),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: PreferredSize(
            preferredSize: Size(ScreenUtil.parentWidth(context), 130),
            child: Stack(
              children: [
                BackgroundWithColor(),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(
                    top: 16.0,
                  ),
                  child: SvgPicture.asset(
                    height: 100,
                    'assets/images/Bukyo.svg',
                    colorFilter: ColorFilter.mode(
                        primaryColor.withOpacity(0.5), BlendMode.srcIn),
                  ),
                ),
                AppBar(
                  elevation: 10,
                  toolbarHeight: 60,
                  leading: BackbuttoninForm(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: const TextTitle(
                    text: 'Feedback',
                    fontWeight: FontWeight.w700,
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  bottom: PreferredSize(
                    preferredSize: Size(ScreenUtil.parentWidth(context), 60),
                    child: ColoredBox(
                      color: primaryColor,
                      child: TabBar(
                        dividerColor: primaryColor,
                        dividerHeight: 0,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        labelColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        tabs: const [
                          Tab(
                            icon: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(Icons.add_comment),
                                Text('Write Feedback')
                              ],
                            ),
                          ),
                          Tab(
                            icon: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(Icons.my_library_books_rounded),
                                Text('Update Feedback')
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: BackgroundWithColor(
              child: Container(
                height: ScreenUtil.parentHeight(context) - 90,
                color: const Color.fromARGB(255, 241, 241, 241),
                padding: const EdgeInsets.only(
                  bottom: 16,
                  right: 24,
                  left: 24,
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  return TabBarView(
                    children: [
                      writeFeedback(constraints, context),
                      updateFeedback(constraints, context),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column writeFeedback(
    BoxConstraints constraints,
    BuildContext context,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return TextFieldFormat(
            fieldHeight: 50,
            borderRadius: 8,
            fieldWidth: constraints.maxWidth,
            controller: driverNameController,
            formText: 'Driver\'s Name',
          );
        }),
        Row(
          children: [
            TextFieldFormat(
              borderRadius: 8,
              fieldHeight: 60,
              fieldWidth: constraints.maxWidth * 0.5,
              controller: bodyNumberController,
              formText: 'Body Number',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: UtilityDropDownMenu(
                hintText: 'Zone',
                width: constraints.maxWidth * 0.47,
                dropDownEntries: zoneList,
                textEditingController: zoneController,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 50,
          width: constraints.maxWidth,
          child: TextFormField(
            textAlignVertical: TextAlignVertical.center,
            readOnly: true,
            controller: dateController,
            cursorColor: primaryColor,
            textAlign: TextAlign.left,
            maxLines: 5,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                color: primaryColor,
                onPressed: () {
                  _pickDate(context);
                },
                icon: const Icon(Icons.date_range_rounded),
              ),
              label: const Text('Date'),
              labelStyle: const TextStyle(color: primaryColor),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: secondaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: primaryColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: primaryColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontSize: 15),
          ),
        ),
        SizedBox(
          height: constraints.maxHeight * 0.20,
          width: constraints.maxWidth,
          child: TextFormField(
            cursorColor: primaryColor,
            textAlign: TextAlign.left,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write Something...',
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
        const Text('Rate your Experience'),
        RatingBar(
          initialRating: starValue,
          glow: false,
          ratingWidget: RatingWidget(
            full: const Icon(
              Icons.star,
              color: accentColor,
            ),
            half: const Icon(
              Icons.star,
              color: accentColor,
            ),
            empty: const Icon(
              Icons.star,
              color: grayInputBox,
            ),
          ),
          onRatingUpdate: (value) {
            starValue = value;
          },
        ),
        PrimaryButton(
          onPressed: () {
            if (anonymous) {}
          },
          buttonText: 'Submit',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoSwitch(
                value: anonymous,
                onChanged: (value) {
                  setState(() {
                    anonymous = value;
                  });
                }),
            const Text('Send Anonymously'),
          ],
        )
      ],
    );
  }

  Column updateFeedback(BoxConstraints constraints, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTitle(
          text: 'My Feedbacks',
          textColor: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(
          height: constraints.maxHeight - 30,
          child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFeedbacks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            minVerticalPadding: 10,
                            contentPadding: const EdgeInsets.all(8),
                            iconColor: accentColor,
                            visualDensity: VisualDensity.comfortable,
                            trailing: IconButton(
                                alignment: Alignment.center,
                                onPressed: () {},
                                icon: const Icon(
                                    Icons.arrow_forward_ios_rounded)),
                            title: Text(
                              "${snapshot.data![index]['Driver Name']}",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Rating',
                                  style: TextStyle(color: grayColor),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: RatingBar(
                                    allowHalfRating: false,
                                    itemSize: 20,
                                    ignoreGestures: true,
                                    initialRating: snapshot.data![index]
                                        ['Rating'],
                                    glow: false,
                                    ratingWidget: RatingWidget(
                                      full: const Icon(
                                        Icons.star,
                                        color: accentColor,
                                      ),
                                      half: const Icon(
                                        Icons.star,
                                        color: accentColor,
                                      ),
                                      empty: const Icon(
                                        Icons.star,
                                        color: grayInputBox,
                                      ),
                                    ),
                                    onRatingUpdate: (value) {},
                                  ),
                                ),
                                const Text(
                                  'Feedback:',
                                  style: TextStyle(color: grayColor),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    '${snapshot.data![index]['Feedback'] != '' ? snapshot.data![index]['Feedback'] : 'No Feedback.'}',
                                    style: TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {},
                          ),
                        );
                      });
                }
                return Center(
                  child: Text('No data.'),
                );
              }),
        )
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picker = await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            datePickerTheme: Theme.of(context).datePickerTheme,
          ),
          child: child!,
        );
      },
      initialDate: DateTime.now(),
      fieldLabelText: 'Date in MM/DD/YY',
      fieldHintText: 'Select Date',
      errorFormatText: 'Select Date',
      context: context,
      firstDate: DateTime.utc(2023, 01, 01),
      lastDate: DateTime.utc(2040, 12, 31),
    );

    if (picker != null) {
      dateController.text = picker.toString().split(" ")[0];
    }
  }

  Future<List<Map<String, dynamic>>> _getFeedbacks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Feedback')
        .where('Commuter UID', isEqualTo: uid)
        .get();
    return snapshot.docs.map((e) => e.data()).toList();
  }

  void _getUID() {
    BookingProvider provider =
        Provider.of<BookingProvider>(context, listen: false);
    uid = provider.bookingUserInfo['UID'];
  }
}
