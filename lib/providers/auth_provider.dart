import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_user.dart';
import '../services/firebase_service.dart';

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final GoogleSignIn googleSignIn;
  final FirebaseService firebaseService;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider(
      {required this.googleSignIn,
      required this.prefs,
      required this.firebaseService});

  String? getFirebaseUserId() {
    return prefs.getString('id');
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && prefs.getString('id')?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> getUserDisplayName() async {
    return prefs.getString('displayName') ?? "";
  }

  Future<bool> handleGoogleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser = await firebaseService.getRemoteUserData(credential);

      if (firebaseUser != null) {
        final List<DocumentSnapshot> document =
            await firebaseService.getRemoteUserList(firebaseUser.uid);
        if (document.isEmpty) {
          firebaseService.firebaseFirestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set({
            'id': firebaseUser.uid,
            'displayName': firebaseUser.displayName,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            'chattingWith': null,
            'photoUrl': 'https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.mirror.co.uk%2Ffeatures%2Fcat-sends-shockwaves-across-social-25638326&psig=AOvVaw1tZdopuXIAQTr-itEUTDgV&ust=1676800053309000&source=images&cd=vfe&ved=0CBAQjRxqFwoTCMiK44blnv0CFQAAAAAdAAAAABAT',
          }); // Add other logic for updating the FireStore data here

          User? currentUser = firebaseUser;
          await prefs.setString('id', currentUser.uid);
        } else {
          DocumentSnapshot documentSnapshot = document[0];
          ChatUser userChat = ChatUser.fromDocument(documentSnapshot);
          await prefs.setString('id', userChat.id);
        }
        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _status = Status.authenticateCanceled;
      notifyListeners();
      return false;
    }
  }

  Future<void> googleSignOut() async {
    _status = Status.uninitialized;
    await FirebaseService().firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
