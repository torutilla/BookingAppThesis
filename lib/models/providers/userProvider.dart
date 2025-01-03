import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_try_thesis/models/firestore_operations/firestoreOperations.dart';
import 'package:flutter_try_thesis/models/providers/argon2.dart';
import 'package:flutter_try_thesis/models/cache_manager/sharedPreferences/userSharedPreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String userID = '';
  Map<String, dynamic> userInfo = {}; //store in cache
  Map<String, dynamic> vehicleInfo = {}; //store in cache
  FirestoreOperations firestoreOperations = FirestoreOperations();
  UserSharedPreferences sharedPreferences = UserSharedPreferences();
  PasswordHashArgon2 argon2Hash = PasswordHashArgon2();
  String password = '';
  Future<void> addUserToDatabase(String uid, {bool isDriver = false}) async {
    final salt = argon2Hash.generateRandomSalt();
    var finalPassword = argon2Hash.generateHashedPassword(password, salt);
    userInfo['Salt'] = salt;
    userInfo['Hash'] = finalPassword;
    userInfo['UID'] = uid;
    userInfo['Role'] = isDriver ? 'Driver' : 'Commuter';
    if (isDriver) {
      userInfo['Verification Status'] = 'Pending';
    }
    try {
      if (userInfo.isNotEmpty) {
        // final userExists = await checkIfUserAlreadyExists(userInfo['UID']);
        // if (userExists.isNotEmpty) {
        //   firestoreOperations.updateDatabaseValues('Users', userExists[0].id, {
        //     'Role': FieldValue.arrayUnion([userInfo['Role']])
        //   });
        // } else {
        await firestoreOperations.addDataToDatabase(
          'Users',
          userInfo,
          onCompleteAdd: (id) {
            userID = id;
          },
        );
        if (isDriver) {
          firestoreOperations.addDataToDatabase(
              'Users',
              documentPath: userID,
              subCollectionPath: 'Vehicle Info',
              vehicleInfo);
        }
        // }
      }
    } catch (e) {
      print('Error adding user: $e');
    }
    notifyListeners();
  }

  void updateUserInfo(
    String fullName,
    String contactNumber,
  ) {
    userInfo = {
      "Full Name": fullName,
      "Contact Number": contactNumber,
    };
    sharedPreferences.addToCache(userInfo);

    notifyListeners();
  }

  void updateVehicleInfo(
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
    vehicleInfo = {
      "Vehicle Type": vehicleType,
      "Operator Name": operatorName,
      "Ownership Type": ownershipType,
      "Zone Number": zone,
      "Body Number": bodyNumber,
      "Plate Number": plateNumber,
      "License Number": licenseNumber,
      "Chassis Number": chassisNumber,
      "MTOP Number": mtopNumber,
    };
    sharedPreferences.addToCache(vehicleInfo);
    notifyListeners();
  }

  // Future<List<QueryDocumentSnapshot>> checkIfUserAlreadyExists(
  //     String uid) async {
  //   final userSnapshots = await firestoreOperations
  //       .retrieveCollectionSnapshots('Users', where: 'UID', equalTo: uid);
  //   return userSnapshots.docs;
  // }
}
