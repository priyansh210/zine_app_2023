import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zineapp2023/screens/onboarding/login/verify_email.dart';
import '../../../../common/navigator.dart';
import 'package:zineapp2023/common/data_store.dart';
import 'package:zineapp2023/providers/user_info.dart';
import '../../../../models/user.dart';
import '../../repo/auth_repo.dart';

class RegisterAuthViewModel extends ChangeNotifier {
  final AuthRepo myRepo;
  final DataStore store;
  final UserProv userProvider;
  RegisterAuthViewModel(
      {required this.store, required this.myRepo, required this.userProvider});

  String _name = "";
  String _email = "";
  String _password = "";
  String _confirmPass = "";

  get name => _name;

  get email => _email;

  get password => _password;

  get confirmPass => _confirmPass;

  setName(String value) {
    _name = value;
  }

  setEmail(String value) {
    _email = value;
  }

  setPassword(String value) {
    _password = value;
  }

  setConfirmPass(String value) {
    _confirmPass = value;
  }

  bool _loading = false;

  bool get loading => _loading;

  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  bool _passwordVisible = false;

  bool get passwordVisible => _passwordVisible;

  void toggleVisible() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  String errorText = "";

  void clearValues() {
    _password = "";
    _email = "";
    _name = "";
    _confirmPass = "";
  }

  Future<void> postDetailsToFirestore(UserModel userModel) async {
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    await firebaseFirestore
        .collection("users")
        .doc(userModel.uid)
        .set(userModel.toJson());
  }


  Future<void> signUpApi(BuildContext context) async {
    var intValue = Random().nextInt(26) + 1;
    var  reg=await myRepo.isUserReg(email);


    Map data = {
      'email': _email.trim(),
      'password': _password.trim(),
      'name': _name.trim(),
      'dp': intValue,
      'type': 'user',
      'registered': reg,
    };

    setLoading(true);

    try {
      var value = await myRepo.createUserWithEmailAndPassword(
        name: data['name'],
        email: data['email'],
        password: data['password'],
      );

      setLoading(false);

      String? uid = value?.uid;

      UserModel userModel = UserModel(
          uid: uid,
          email: data['email'],
          name: data['name'],
          dp: data['dp'],
          type: data['type'],
          rooms:[],
          registered: data['registered']);
      postDetailsToFirestore(userModel);

      await Navigator.of(NavigationService.navigatorKey.currentContext!,
              rootNavigator: true)
          .push(
              CupertinoPageRoute(builder: (ctx) => const VerifyEmailScreen()));
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          errorText = "This email is already in use, Contact Team Zine";
          break;
        case "internal-error":
          errorText = "An internal error occurred. Please try again later.";
          break;
        case "network-request-failed":
          errorText =
              "Network Request Error. Please check your internet and try again";
          break;
        case "user-disabled":
          errorText = "User with this email has been disabled";
          break;
        case "too-many-requests":
          errorText = "Too many requests";
          break;
        case "quota-exceeded":
          errorText = "Quota Exceeded. Please contact Team Zine.";
          break;
        case "timeout":
          errorText = "Timeout. Please check you internet and try again later";
          break;
        case "operation-not-allowed":
          errorText = "Signing in with Email and Password is not enabled";
          break;
        default:
          errorText = "An undefined Error happened";
      }
      setLoading(false);

      Fluttertoast.showToast(
          msg: errorText,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red);
    }
  }

  void signOut() {
    myRepo.signOut();
  }
}
