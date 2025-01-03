import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/account_management_pages/otpAuth.dart';
import 'package:flutter_try_thesis/account_management_pages/uploadID.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/backButton.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/background.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/linkText.dart';
import 'package:flutter_try_thesis/constants/logoMain.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/textFields.dart';
import 'package:flutter_try_thesis/constants/utility_widgets/utilButton.dart';
import 'package:flutter_try_thesis/models/providers/userProvider.dart';
import 'package:flutter_try_thesis/constants/zones.dart';
import 'package:flutter_try_thesis/routing/router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../account_management_pages/login.dart';
import '../../../constants/constants.dart';
import '../../../constants/utility_widgets/customCard.dart';
import '../../../constants/titleText.dart';

class VehicleRegistration extends StatefulWidget {
  const VehicleRegistration({super.key});

  @override
  State<VehicleRegistration> createState() => _VehicleRegistrationState();
}

class _VehicleRegistrationState extends State<VehicleRegistration> {
  bool removeIcon = false;
  int currIndex = 0;
  final ImagePicker photoPicker = ImagePicker();
  XFile? uploadedImage;
  List<Widget> uploadedImageColumn = [];
  List<String> photoPath = [];

  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _bodyNumberController = TextEditingController();
  final TextEditingController _mtopNumberController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _chassisNumberController =
      TextEditingController();
  final TextEditingController _ownershipTypeController =
      TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<CustomCardState> _cardState = GlobalKey<CustomCardState>();

  final ScrollController _formScroller = ScrollController();
  late ValueNotifier<bool> iconNotifier;

  @override
  void initState() {
    iconNotifier = ValueNotifier(removeIcon);
    uploadedImageColumn = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardState.currentState!.draggableController.addListener(() {
        if (_cardState.currentState!.draggableController.size == 1.0) {
          removeIcon = true;
        } else {
          removeIcon = false;
        }
      });
    });
    super.initState();
  }

  // void _handleUpload() async {
  //   XFile? image = await photoPicker.pickImage(source: ImageSource.gallery);

  //   if (image != null) {
  //     setState(() {
  //       photoPath.add(image.path);
  //       uploadedImage = image;
  //       uploadedImageColumn.add(imageInColumn(image, currIndex));
  //       currIndex++;
  //     });
  //     _showSnackbar('Successfully added image', context);
  //   }
  // }

  // Widget imageInColumn(XFile uploadedImage, int index) {
  //   return Card(
  //     key: Key(uploadedImage.name),
  //     surfaceTintColor: secondaryColor,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         const Icon(
  //           Icons.filter,
  //           color: primaryColor,
  //         ),
  //         SizedBox(
  //           width: 100,
  //           child: Text(
  //             uploadedImage.name,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ),
  //         IconButton(
  //           onPressed: () {
  //             setState(() {
  //               uploadedImageColumn
  //                   .removeAt(removeCurrentImageIndex(uploadedImage.name));
  //             });
  //           },
  //           icon: const Icon(Icons.close),
  //           color: primaryColor,
  //           style: ButtonStyle(
  //             backgroundColor: WidgetStateProperty.resolveWith<Color?>(
  //               (state) {
  //                 if (state.contains(WidgetState.pressed)) {
  //                   return Colors.transparent;
  //                 }
  //                 return null;
  //               },
  //             ),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  // int removeCurrentImageIndex(String imageKey) {
  //   int index = 0;
  //   for (index; index < uploadedImageColumn.length; index++) {
  //     if (imageKey == uploadedImageColumn[index].key.toString()) {
  //       return index;
  //     }
  //   }
  //   return index - 1;
  // }

  @override
  Widget build(BuildContext context) {
    double containerWidth = 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: _formScroller,
          child: Form(
            key: _formKey,
            child: BackgroundWithColor(
              child: Stack(
                children: [
                  Stack(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        leading: BackbuttoninForm(
                          onPressed: () {
                            MyRouter.navigateToPrevious(context);
                          },
                        ),
                      ),
                      Container(
                        height: ScreenUtil.parentHeight(context) * 0.20,
                        alignment: Alignment.center,
                        child: MainLogo(logoHeight: 70, logoWidth: 200),
                      ),
                    ],
                  ),
                  CustomizedCard(
                    key: _cardState,
                    cardWidth: ScreenUtil.parentWidth(context),
                    cardHeight: ScreenUtil.parentHeight(context) * 0.80,
                    cardRadius: 50.0,
                    enableDraggableScrollable: true,
                    childWidget: LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: iconNotifier,
                            builder: (context, value, child) {
                              return removeIcon
                                  ? Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons
                                                .keyboard_double_arrow_down_rounded,
                                            size: 32,
                                            color:
                                                Colors.black.withOpacity(0.2),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons
                                                .keyboard_double_arrow_up_rounded,
                                            size: 32,
                                            color:
                                                Colors.black.withOpacity(0.2),
                                          ),
                                        ],
                                      ),
                                    );
                            },
                          ),
                          const Column(
                            children: [
                              TextTitle(
                                text: 'VEHICLE REGISTRATION',
                                textColor: primaryColor,
                              ),
                              Text(
                                'Register your vehicle',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w300,
                                    color: accentColor),
                              ),
                            ],
                          ),
                          ClipRect(
                            child: Container(
                              width: containerWidth =
                                  ScreenUtil.parentWidth(context),
                              height: constraints.maxHeight * 0.7,
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // TextFieldFormat(
                                    //   controller: _vehicleTypeController,
                                    //   borderRadius: 8,
                                    //   fieldWidth: containerWidth * 0.8,
                                    //   fieldHeight: 64,
                                    //   formText: 'Vehicle Type',
                                    //   suffixIcon: Padding(
                                    //     padding: const EdgeInsets.symmetric(
                                    //         horizontal: 8),
                                    //     child: DropdownButton(
                                    //       underline: const ColoredBox(
                                    //           color: Colors.transparent),
                                    //       onChanged: (value) {
                                    //         setState(() {
                                    //           _vehicleTypeController.text =
                                    //               value!;
                                    //         });
                                    //       },
                                    //       items: List.generate(2, (index) {
                                    //         List<String> title = [
                                    //           'Bukyo',
                                    //           'Tricycle'
                                    //         ];
                                    //         return DropdownMenuItem(
                                    //             value: title[index],
                                    //             child: Text(title[index]));
                                    //       }),
                                    //     ),
                                    //   ),
                                    // ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: DropdownMenu(
                                          controller: _vehicleTypeController,
                                          menuHeight: 100,
                                          width: containerWidth * 0.8,
                                          enableSearch: true,
                                          label: const Text('Vehicle Type'),
                                          dropdownMenuEntries: const [
                                            DropdownMenuEntry(
                                                value: 'Bukyo', label: 'Bukyo'),
                                            DropdownMenuEntry(
                                                value: 'Tricycle',
                                                label: 'Tricycle'),
                                          ]),
                                    ),
                                    TextFieldFormat(
                                      controller: _ownerController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'Name of Registered Owner',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }
                                        return null;
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: DropdownMenu(
                                          controller: _ownershipTypeController,
                                          menuHeight: 100,
                                          width: containerWidth * 0.8,
                                          enableSearch: true,
                                          label: const Text('Ownership'),
                                          dropdownMenuEntries: const [
                                            DropdownMenuEntry(
                                                value: 'Owner', label: 'Owner'),
                                            DropdownMenuEntry(
                                                value: 'Operator',
                                                label: 'Operator'),
                                          ]),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: DropdownMenu(
                                        controller: _zoneController,
                                        menuHeight: 100,
                                        width: containerWidth * 0.8,
                                        enableSearch: true,
                                        label: const Text('Zone'),
                                        dropdownMenuEntries: List.generate(
                                          zoneList.length,
                                          (index) {
                                            return DropdownMenuEntry(
                                                value: zoneList.keys
                                                    .elementAt(index),
                                                label: zoneList.keys
                                                    .elementAt(index));
                                          },
                                        ),
                                      ),
                                    ),

                                    TextFieldFormat(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: _bodyNumberController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'Body Number',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }
                                        final regex = RegExp(r'^[0-9]{4}$');

                                        if (!regex.hasMatch(value)) {
                                          return 'Invalid Contact Number';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFieldFormat(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: _mtopNumberController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'MTOP Number',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }
                                        final regex = RegExp(r'^[A-Z0-9]');
                                        if (!regex.hasMatch(value)) {
                                          return 'Invalid MTOP Number';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFieldFormat(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: _chassisNumberController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'Chassis Number',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }
                                        final regex = RegExp(r'^[A-Z0-9]{1,}$');
                                        if (!regex.hasMatch(value)) {
                                          return 'Invalid Chassis Number';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFieldFormat(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: _plateNumberController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'Plate Number',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }
                                        final regex =
                                            RegExp(r'^[A-Z0-9]{3}[0-9]*$');
                                        if (!regex.hasMatch(value)) {
                                          return 'Invalid Plate Number';
                                        }

                                        return null;
                                      },
                                    ),
                                    TextFieldFormat(
                                      controller: _licenseNumberController,
                                      borderRadius: 8,
                                      fieldWidth: containerWidth * 0.8,
                                      fieldHeight: 64,
                                      formText: 'License Number',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field can\'t be empty';
                                        }

                                        return null;
                                      },
                                    ),
                                    // Container(
                                    //   width: ScreenUtil.parentWidth(context) *
                                    //       0.70,
                                    //   height: ScreenUtil.parentWidth(context) *
                                    //       0.50,
                                    //   margin: const EdgeInsets.only(bottom: 8),
                                    //   decoration: ShapeDecoration(
                                    //     shape: RoundedRectangleBorder(
                                    //       borderRadius:
                                    //           BorderRadius.circular(10),
                                    //     ),
                                    //     color: secondaryColor.withOpacity(0.2),
                                    //   ),
                                    //   child: DottedBorder(
                                    //     color: secondaryColor,
                                    //     dashPattern: const [6, 3, 6, 3],
                                    //     radius: const Radius.circular(10),
                                    //     borderType: BorderType.RRect,
                                    //     child: Center(
                                    //       child: GestureDetector(
                                    //         onTap: _handleUpload,
                                    //         child: Column(
                                    //           mainAxisAlignment:
                                    //               MainAxisAlignment.center,
                                    //           children: [
                                    //             const Icon(
                                    //               Icons.cloud_upload_rounded,
                                    //               size: 70,
                                    //               color: primaryColor,
                                    //             ),
                                    //             const TextTitle(
                                    //               text:
                                    //                   'Upload your files here',
                                    //               textColor: primaryColor,
                                    //               fontSize: 15,
                                    //               fontWeight: FontWeight.w400,
                                    //             ),
                                    //             TextLink(
                                    //               onPressed: _handleUpload,
                                    //               linktext: 'Browse',
                                    //             ),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    // uploadedImageColumn.isNotEmpty
                                    //     ? SizedBox(
                                    //         height: ScreenUtil.parentHeight(
                                    //                 context) *
                                    //             0.10,
                                    //         width: ScreenUtil.parentWidth(
                                    //                 context) *
                                    //             0.80,
                                    //         child: Material(
                                    //           color: Colors.white,
                                    //           child: ListView.builder(
                                    //             itemCount:
                                    //                 uploadedImageColumn.length,
                                    //             itemBuilder: (context, index) {
                                    //               return ListTile(
                                    //                 title: uploadedImageColumn[
                                    //                     index],
                                    //               );
                                    //             },
                                    //           ),
                                    //         ),
                                    //       )
                                    //     : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Consumer<UserProvider>(
                                  builder: (context, userProvider, child) {
                                return PrimaryButton(
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _updateVehicleInfo(
                                        _ownerController.text,
                                        _ownershipTypeController.text,
                                        _bodyNumberController.text,
                                        _mtopNumberController.text,
                                        _licenseNumberController.text,
                                        _plateNumberController.text,
                                        _vehicleTypeController.text,
                                        _chassisNumberController.text,
                                        _zoneController.text,
                                      );
                                      // MyRouter.navigateToNext(
                                      //     context, UploadIDCard());
                                      MyRouter.navigateToNext(
                                          context,
                                          OtpPage(
                                            contactNumber: userProvider
                                                .userInfo['Contact Number'],
                                            isRider: true,
                                          ));
                                    } else {
                                      _showSnackbar(
                                          'Some inputs are empty or invalid. Please check your entries and try again.',
                                          context);
                                    }
                                  },
                                  buttonText: 'Continue',
                                  textColor: Colors.white,
                                  borderRadius: 8,
                                  backgroundColor: primaryColor,
                                );
                              }),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Already have an account?'),
                                  TextLink(
                                    onPressed: () {
                                      MyRouter.navigateToNextPermanent(
                                        context,
                                        const LoginForm(),
                                      );
                                    },
                                    linktext: 'Login',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String s, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void _updateVehicleInfo(
    String operatorName,
    String ownershipType,
    String bodyNumber,
    String mtopNumber,
    String licenseNumber,
    String plateNumber,
    String vehicleType,
    String chassisNumber,
    String zone,
  ) {
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.updateVehicleInfo(
        operatorName,
        ownershipType,
        bodyNumber,
        mtopNumber,
        licenseNumber,
        plateNumber,
        vehicleType,
        chassisNumber,
        zone);
  }

  void uploadImage() {}
}
