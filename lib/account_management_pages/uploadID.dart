import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/account_management_pages/otpAuth.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/backButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/customCard.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/linkText.dart';
import 'package:flutter_try_thesis/constants/logoMain.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/providers/userProvider.dart';
import 'package:flutter_try_thesis/models/uploadImage.dart';
import 'package:flutter_try_thesis/routing/router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UploadIDCard extends StatefulWidget {
  const UploadIDCard({super.key});

  @override
  UploadIDCardState createState() => UploadIDCardState();
}

class UploadIDCardState extends State<UploadIDCard> {
  int currIndex = 0;
  final ImagePicker photoPicker = ImagePicker();
  XFile? uploadedImage;
  List<Map<String, dynamic>> uploadedImageList = [];

  ImageUpload imageUpload = ImageUpload();

  @override
  void initState() {
    super.initState();
  }

  void _handleUpload() async {
    showDialog(
        barrierColor: Colors.black12,
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Center(
              child: CircularProgressIndicator(
            color: accentColor,
          ));
        });
    XFile? image = await photoPicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final size = await image.length();
      final sizeInMB = size / (1024 * 1024);
      setState(() {
        uploadedImageList.add({
          "File": image,
          "Size": '${sizeInMB.toStringAsFixed(2)} MB',
        });
      });
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
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
                      const TextTitle(
                        text: 'Upload images',
                        textColor: primaryColor,
                      ),
                      Container(
                        width: ScreenUtil.parentWidth(context) * 0.80,
                        height: ScreenUtil.parentWidth(context) * 0.50,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: secondaryColor.withOpacity(0.2),
                        ),
                        child: DottedBorder(
                          color: secondaryColor,
                          dashPattern: const [6, 3, 6, 3],
                          radius: const Radius.circular(10),
                          borderType: BorderType.RRect,
                          child: Center(
                            child: GestureDetector(
                              onTap: _handleUpload,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_rounded,
                                    size: 70,
                                    color: primaryColor,
                                  ),
                                  const TextTitle(
                                    text: 'Upload your files here',
                                    textColor: primaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  TextLink(
                                    onPressed: _handleUpload,
                                    linktext: 'Browse',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: ScreenUtil.parentHeight(context) * 0.20,
                        width: ScreenUtil.parentWidth(context) * 0.80,
                        child: ListView.builder(
                          itemCount: uploadedImageList.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 235, 235, 235),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                trailing: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        uploadedImageList.removeAt(index);
                                      });
                                    },
                                    icon: Icon(Icons.close)),
                                title: Text(
                                  uploadedImageList[index]['File'].name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                  '${uploadedImageList[index]['Size']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                leading: Icon(Icons.image),
                                onTap: () {
                                  XFile file = uploadedImageList[index]['File'];
                                  showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.transparent,
                                        contentPadding: EdgeInsets.all(16),
                                        content: Image.file(
                                          File(file.path),
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      PrimaryButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              });
                          for (var image in uploadedImageList) {
                            final String storagePath =
                                'userDriver_${image['File'].name}'; //change
                            imageUpload.uploadImageToFirebase(
                                image['File'],
                                storagePath,
                                _handleSuccessfulUpload,
                                _onErrorUpload);
                          }
                        },
                        buttonText: 'Continue',
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuccessfulUpload(UploadTask uploadTask) {
    final provider = Provider.of<UserProvider>(context, listen: false);
    Navigator.of(context).pop();
    MyRouter.navigateToNext(
        context,
        OtpPage(
          isRider: true,
          contactNumber: provider.userInfo['Contact Number'],
        ));
  }

  void _onErrorUpload() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'An error occured on uploading the file. Please try again later.')));
  }
}
