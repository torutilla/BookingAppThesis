import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUpload {
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  Future<XFile?> selectImage() async {
    final ImagePicker imagePicker = ImagePicker();
    return await imagePicker.pickImage(source: ImageSource.gallery);
  }

  void uploadImageToFirebase(
      XFile file,
      String storagePath,
      void Function(UploadTask uploadTask)? callBack,
      void Function()? onError) {
    try {
      File uploadFile = File(file.path);
      final rootRef = firebaseStorage.ref();
      final storageRef = rootRef.child('driverUploads/$storagePath');
      UploadTask uploadTask = storageRef.putFile(uploadFile);
      if (callBack != null) {
        callBack(uploadTask);
      }
    } catch (e) {
      if (onError != null) {
        onError();
      }
    }
  }
}
